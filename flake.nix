{
  description =
    "Provides NixOS configuration for the Raspberry Pi at my mum's place";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    my-nixos.url = "github:bjackman/nixos-flake?ref=master";
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      mkSandyConfig = hostName: nixpkgs.lib.nixosSystem {
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

            networking.hostName = hostName;

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

            system.stateVersion = "25.05";

            # Note this requires running `sudo tailscale up` on the target to set up.
            # To avoid this we'd need to put the auth key into the disk image.
            # Most of the ways that I could see for doing that woudl also leak
            # it into the Nix store which is not a great idea.
            # I think the most practical way is to just build the disk image and
            # then splat the key into it as a post-processing step (e.g.
            # libguestfs/virt-customize) and then point to the key via
            # services.tailscale.authKeyFile. But, whatever.
            services.tailscale.enable = true;
          })
        ];
      };
    in {
      nixosConfigurations.sandy = mkSandyConfig "sandy";
      nixosConfigurations.sandy-staging = mkSandyConfig "sandy-staging";

      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [ nixfmt-classic nixos-rebuild libguestfs-with-appliance ];
      };
    };
}
