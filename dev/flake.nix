# TODO:
# * validate env and paths
# * make non nixos paths optional (/etc/static)
# * use library to auto generate `system` and auto load `NIX_FRAGMENT`
{
    description = "Base development project flake with sandboxing";

    outputs = { self, nixpkgs }: let
        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit system; };
    in {
        devShells.${system}.default = pkgs.mkShell {
            packages = [];

            shellHook = /*bash*/ ''
                NIX_FRAGMENT="default"
                EMU_DIR="$PWD/.devshells"
                EMU_DIR_ROOT="$EMU_DIR/efs-root"
                EMU_DIR_HOME="$EMU_DIR_ROOT/home/$USER"
                PROGRAM="$TERM"
                # Setup, Env, Root, Network, Runtime, User FS
                BWRAP_ARGS=(
                    \
                    --unshare-all \
                    --clearenv \
                    --die-with-parent \
                    --chdir "$PWD" \
                    \
                    --setenv USER "$USER" \
                    --setenv HOME "$HOME" \
                    --setenv PATH "$PATH" \
                    --setenv LANG "$LANG" \
                    --setenv TERM "$TERM" \
                    \
                    --bind "$EMU_DIR_ROOT" "/" \
                    --dev /dev                 \
                    --proc /proc               \
                    --tmpfs /tmp               \
                    \
                    --share-net                                   \
                    --ro-bind /etc/resolv.conf /etc/resolv.conf   \
                    --ro-bind /etc/ssl /etc/ssl                   \
                    --ro-bind /etc/static/ssl /etc/static/ssl     \
                    \
                    --ro-bind "/nix/store" "/nix/store"           \
                    --ro-bind /bin /bin                           \
                    --ro-bind /usr /usr                           \
                    --ro-bind /lib64 /lib64                       \
                    \
                    --bind "$EMU_DIR_HOME" "$HOME"                \
                    --bind "$PWD" "$PWD"                          \
                    --ro-bind "$PWD/flake.nix" "$PWD/flake.nix"   \
                    --ro-bind "$PWD/flake.lock" "$PWD/flake.lock" \
                    \
                )

                if [[ ! -d "$EMU_DIR_HOME" ]]; then # Check and create the deepest to auto create the entire directory.
                    mkdir -p "$EMU_DIR_HOME"
                fi

                readarray -d ':' -t nixpaths <<< "$PATH" # Loads and binds the host's $PATH
                for nixpath in "''${nixpaths[@]}"; do
                    if [[ -e "$nixpath" ]]; then
                        BWRAP_ARGS+=(--ro-bind "$nixpath" "$nixpath")
                    fi
                done

                if [[ -f ./.devshellshook.sh ]]; then
                    BWRAP_ARGS+=(--ro-bind "$PWD/.devshellshook.sh" "$PWD/.devshellshook.sh")
                    source ./.devshellshook.sh
                fi

                exec ${pkgs.bubblewrap}/bin/bwrap \
                    "''${BWRAP_ARGS[@]}" \
                    "$PROGRAM"
            '';
        };
    };

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };
}
