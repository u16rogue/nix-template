{
    description = "Nix flake templates";

    outputs = { self }: {
        templates = {
            dev = {
                path = ./dev;
            };
        };
    };
}
