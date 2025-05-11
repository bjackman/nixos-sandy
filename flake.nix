{
  description =
    "Provides NixOS configuration for the Raspberry Pi at my mum's place";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    my-nixos.url = "github:bjackman/nixos-flake?ref=master";
  };

  outputs = inputs@{ nixpkgs, ... }:
    let pkgs = import nixpkgs { system = "x86_64-linux"; };
    in {
      nixosConfigurations.sandy = nixpkgs.lib.nixosSystem {
        modules = [
          inputs.my-nixos.nixosModules.brendan
          ({ modulesPath, ... }: {
            imports = [
              "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
            ];

            # Hmm, seems like cross-compilation is a bit of a mess, so here we just
            # assume that this will always be built on a proper american computer
            nixpkgs.buildPlatform = "x86_64-linux";
            nixpkgs.hostPlatform = "aarch64-linux";

            networking.hostName = "sandy";

            virtualisation.vmVariant.virtualisation = {
              forwardPorts = [{
                from = "host";
                host.port = 2222;
                guest.port = 22;
              }];
              graphics = false;
              # Point to the x86 packages for running QEMU etc.
              host.pkgs = pkgs;
            };
          })
        ];
      };

      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [ nixfmt-classic nixos-rebuild ];
      };
    };
}
