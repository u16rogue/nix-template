{
    description = "Nix flake templates";

    outputs = { self }: {
        templates = {
            default = self.templates.basic;

            dev = {
                path = ./dev;
                description = "Development nix template with sandboxing";
            };
        };
    };
}
