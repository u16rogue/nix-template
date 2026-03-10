#!/usr/bin/env bash

# TODO: find work around to nix daemon socket
#       without the socket nix will use its own "root"
#       located at ~/.local/share/nix which causes multiple
#       duplicates. this is solved by mounting the nix daemon socket
#       and allowing the sandboxed nix to install packages in the
#       host /nix/store which may or may not be a point of failure.

assert_command() {
    if ! command -v "$1" &> /dev/null; then
       echo "[error] '$1' not available." >&2
       exit 1
    fi
}

assert_env() {
    local var_name="$1"
    local value="${!var_name}"

    if [[ -z "$var_name" ]]; then
        echo "[error] no variable name provided" >&2
        exit 1
    fi

    if [[ ! -v "$var_name" ]]; then
        echo "[error] '$var_name' is not set" >&2
        exit 1
    fi

    if [[ -z "$value" ]]; then
        echo "[error] '$var_name' is set but empty" >&2
        exit 1
    fi
}

assert_env_path() {
    local var_name="$1"
    local value="${!var_name}"

    assert_env "$var_name"

    if [[ ! -e "$value" ]]; then
        echo "[error] '$var_name' points to a non-existent path: '$value'" >&2
        exit 1
    fi
}

# ====================================================================================================

assert_command "env"
assert_command "which"
assert_command "realpath"
assert_command "nix"
assert_command "bwrap"
assert_command "nologin"

assert_env NIX_FRAGMENT
assert_env HOSTNAME
assert_env PATH
assert_env LANG
assert_env TERM
assert_env SHELL

assert_env_path HOME
assert_env_path PWD

# ====================================================================================================

EMU_DIR="$PWD/.devshells"
EMU_DIR_ROOT="$EMU_DIR/efs-root"
EMU_DIR_HOME="$EMU_DIR_ROOT/home/$USER"

PROGRAM="$SHELL"
PROGRAM_ARGS=()

# ====================================================================================================

# Setup devshell directory
if [[ ! -d "$EMU_DIR_HOME" ]]; then
    if ! mkdir -p "$EMU_DIR_HOME"; then # creating the deepest path to create all path in one command
        echo "[error] failed to create project's devshell folder"
        exit 1
    fi
fi

# ====================================================================================================

# Base config
BWRAP_ARGS=( \
    --unshare-all                   \
    --clearenv                      \
    --die-with-parent               \
    --chdir "$PWD"                  \
    --hostname "devshell-$HOSTNAME" \
    --bind "$EMU_DIR_ROOT" "/"      \
    --bind "$EMU_DIR_HOME" "$HOME"  \
    --bind "$PWD" "$PWD"            \
)

# --- NO `--bind` BEYOND THIS POINT ---

# Setup env
BWRAP_ARGS+=( \
    --setenv USER "$USER" \
    --setenv HOME "$HOME" \
    --setenv LANG "$LANG" \
    --setenv TERM "$TERM" \
    --setenv NIX_CONFIG   \
        " \
            experimental-features = nix-command flakes
        " \
)

# Setup fs
BWRAP_ARGS+=( \
    --dev /dev              \
    --proc /proc            \
    --tmpfs /tmp            \
    --ro-bind /lib64 /lib64 \
    --ro-bind /nix /nix     \
)

# Setup PATH
BWRAP_ARGS+=( \
    --setenv PATH "$PATH"                             \
    --ro-bind "$(realpath /bin/sh)" /bin/sh           \
    --ro-bind "$(realpath /usr/bin/env)" /usr/bin/env \
)

readarray -d ':' -t host_paths <<< "$PATH"
for host_path in "''${host_paths[@]}"; do
    if [[ -e "$host_path" ]]; then
        BWRAP_ARGS+=(--ro-bind "$host_path" "$host_path")
    fi
done

# Setup network
BWRAP_ARGS+=( \
    --share-net                                 \
    --ro-bind /etc/resolv.conf /etc/resolv.conf \
    --ro-bind /etc/ssl /etc/ssl                 \
    --ro-bind /etc/static/ssl /etc/static/ssl   \
)

# Setup user
NOLOGIN="$(realpath "$(which "nologin")")"
if [[ ! -f "$NOLOGIN" ]]; then
    echo "[error] invalid nologin: '$NOLOGIN'"
fi

EMU_PASSWD="$EMU_DIR/passwd"
EMU_GROUP="$EMU_DIR/group"
if [[ ! -e "$EMU_PASSWD" ]]; then
    echo "root:x:0:0:System administrator:/root:$NOLOGIN" > "$EMU_PASSWD"
    echo "$(id -un):x:$(id -u):$(id -g)::$HOME:$NOLOGIN" >> "$EMU_PASSWD"
fi
BWRAP_ARGS+=(--ro-bind "$EMU_PASSWD" /etc/passwd)

if [[ ! -e "$EMU_GROUP" ]]; then
    echo "root:x:0:" > "$EMU_GROUP"
    echo "$(id -gn):x:$(id -g):" >> "$EMU_GROUP"
fi
BWRAP_ARGS+=(--ro-bind "$EMU_GROUP" /etc/group)

# Setup devshell and ensure it cant be changed inside the sandbox
BWRAP_ARGS+=( \
    --ro-bind "$PWD/flake.nix" "$PWD/flake.nix"                 \
    --ro-bind "$PWD/flake.lock" "$PWD/flake.lock"               \
    --ro-bind "$PWD/.devshellshook.sh" "$PWD/.devshellshook.sh" \
)

# Setup development and nix env's
while IFS='=' read -r key value; do
    case "$key" in
        NIX_*|CMAKE_*|PKG_CONFIG_*|SOURCE_DATE_EPOCH)
            BWRAP_ARGS+=(--setenv "$key" "$value")
            ;;
    esac
done < <(env)

BWRAP_ARGS+=( \
    --setenv CPM_SOURCE_CACHE "${CPM_SOURCE_CACHE:-"$HOME/.cache/cmake-cpm"}" \
)

# opt auto setup fish shell
if command -v fish &> /dev/null; then
    BWRAP_ARGS+=(--setenv SHELL "$(which fish)")
    FISH_CONFIG_PATH="$HOME/.config/fish"
    [[ -e "$FISH_CONFIG_PATH" ]] && BWRAP_ARGS+=(--ro-bind "$FISH_CONFIG_PATH" "$FISH_CONFIG_PATH")
fi

# opt auto setup zellij
if command -v zellij &> /dev/null; then
    PROGRAM="$(which zellij)"
    ZELLIJ_CONFIG_PATH="$HOME/.config/zellij"
    [[ -e "$ZELLIJ_CONFIG_PATH" ]] && BWRAP_ARGS+=(--ro-bind "$ZELLIJ_CONFIG_PATH" "$ZELLIJ_CONFIG_PATH")
    ZELLIJ_LAYOUT_PATH="$PWD/.zellij.kdl"
    [[ -f "$ZELLIJ_LAYOUT_PATH" ]] && PROGRAM_ARGS+=(--layout "$ZELLIJ_LAYOUT_PATH")
    PROGRAM_ARGS+=(attach --create "main")
fi

# ====================================================================================================

BWRAP_ARGS+=(\
    --ro-bind "$EMU_DIR" "$EMU_DIR" \
)

# ====================================================================================================

echo "exec $PROGRAM ${PROGRAM_ARGS[*]}" > "$EMU_DIR/entrypoint.sh"

exec bwrap \
    "${BWRAP_ARGS[@]}" \
    "--" \
    "$PROGRAM" \
    "${PROGRAM_ARGS[@]}"
