{
    description = "Description";

    outputs = { self, nixpkgs }: let
        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit system; };
    in {
        devShells.${system}.default = pkgs.mkShell {
            packages = [];

            shellHook = /*bash*/ ''
                export NIX_FRAGMENT="default"
                if [[ -f "$PWD/.devshellshook.sh" ]]; then
                    source "$PWD/.devshellshook.sh"
                fi
            '';
        };
    };

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    };
}
