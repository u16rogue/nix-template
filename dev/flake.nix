{
    description = "Project flake description";

    outputs = { self, nixpkgs }: let
        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit system; };
    in {
        devShells.${system}.default = pkgs.mkShell {
            packages = [];

            # TODO: validate env and values
            shellHook = /*bash*/ ''
                NIX_FRAGMENT="default"
                EMU_HOME="$PWD/.devshells/home/$USER"
                PROGRAM="$TERM"
                BWRAP_ARGS=(
                    --unshare-all \
                    --share-net \
                    \
                    --clearenv \
                    --setenv USER "$USER" \
                    --setenv HOME "$HOME" \
                    --setenv PATH "$PATH" \
                    --setenv LANG "$LANG" \
                    --setenv TERM "$TERM" \
                    \
                    --dev /dev   \
                    --proc /proc \
                    --tmpfs /tmp \
                    \
                    --ro-bind "/nix/store" "/nix/store"           \
                    --ro-bind /bin /bin                           \
                    --ro-bind /usr /usr                           \
                    --ro-bind /lib64 /lib64                       \
                    --ro-bind /etc/resolv.conf /etc/resolv.conf   \
                    --ro-bind /etc/ssl /etc/ssl                   \
                    --ro-bind /etc/static/ssl /etc/static/ssl     \
                    --bind "$EMU_HOME" "$HOME"                    \
                    --bind "$PWD" "$PWD"                          \
                    --ro-bind "$PWD/flake.nix" "$PWD/flake.nix"   \
                    --ro-bind "$PWD/flake.lock" "$PWD/flake.lock" \
                    \
                    --chdir "$PWD" \
                )

                if [[ ! -d "$EMU_HOME" ]]; then
                    mkdir -p "$EMU_HOME"
                fi

                readarray -d ':' -t nixpaths <<< "$PATH"
                for nixpath in "''${nixpaths[@]}"; do
                    if [[ -e "$nixpath" ]]; then
                        BWRAP_ARGS+=(--ro-bind "$nixpath" "$nixpath")
                    fi
                done
                
                if [[ -f ./devshellshook.sh ]]; then
                    BWRAP_ARGS+=(--ro-bind "$PWD/devshellshook.sh" "$PWD/devshellshook.sh")
                    source ./devshellshook.sh
                fi

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
