{
    description = "Nix flake templates";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        flake-parts.url = "github:hercules-ci/flake-parts";
    };

    outputs = inputs@{ flake-parts, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
        systems = [ "x86_64-linux" ];
        imports = [];
        flake = {
            description = "Template Description";
            templates = {
                dev.path = ./dev;
                dev-cpp.path = ./dev-cpp;
            };
        };
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
