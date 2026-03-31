{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        flake-parts.url = "github:hercules-ci/flake-parts";
    };

    outputs = inputs@{ flake-parts, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
        flake.description = "Template Description";
        imports = [];
        systems = [ "x86_64-linux" ];
        perSystem = { pkgs, ... }: {
            devShells.default = pkgs.mkShellNoCC {
                packages = [];
                shellHook = /*bash*/ ''
                    export NIX_FRAGMENT="default"
                    if [[ -f "$PWD/.devshellshook.sh" ]]; then
                        source "$PWD/.devshellshook.sh"
                    fi
                '';
            };
        };
    };
}
