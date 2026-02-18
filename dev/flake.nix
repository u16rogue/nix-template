{
    description = "Project flake description";

    outputs = { self, nixpkgs }: let
        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit system; };
    in {
        devShells.${system}.default = pkgs.mkShell {
            packages = [];

            # TODO: run checks and ensure env's are valid etc
            # fail with exit rather than enter a broken state
            shellHook = /*bash*/ ''
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
                    --ro-bind "/nix/store" "/nix/store" \
                    --bind "$EMU_HOME" "$HOME"          \
                    --bind "$PWD" "$PWD"                \
                    \
                    --chdir "$PWD" \
                )

                if [ ! -d "$EMU_HOME" ]; then
                    mkdir -p "$EMU_HOME"
                fi

                readarray -d ':' -t nixpaths <<< "$PATH"
                for nixpath in "''${nixpaths[@]}"; do
                    if [[ -e "$nixpath" ]]; then
                        BWRAP_ARGS+=(--ro-bind "$nixpath" "$nixpath")
                    fi
                done
                
                if [[ -f ./devshellshook.sh ]]; then
                    source ./devshellshook.sh
                fi

                if [[ -f ./.devshellshook.sh ]]; then
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
