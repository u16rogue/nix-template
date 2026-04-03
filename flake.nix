{
    description = "Nix flake templates";

    outputs = { self }: {
        templates = {
            dev.path = ./dev;
            dev-cpp.path = ./dev-cpp;
        };
    };
}
