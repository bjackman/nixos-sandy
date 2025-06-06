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
      tailscaleAuthKeyFile = "/var/tmp/tailscale-auth-key"; # /var/tmp I guess...?
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
            services.tailscale = {
              enable = true;
              authKeyFile = tailscaleAuthKeyFile;
            };
          })
        ];
      };
    in {
      nixosConfigurations.sandy = mkSandyConfig "sandy";
      nixosConfigurations.sandy-staging = mkSandyConfig "sandy-staging";

      # Just for convenience.
      packages.x86_64-linux = {
        sdImage = self.nixosConfigurations.sandy.config.system.build.sdImage;
        sdImageStaging = self.nixosConfigurations.sandy-staging.config.system.build.sdImage;

        # In order to bring up the device and have it connect immediately to
        # Tailscale, we want to put an Auth Key into the image. But, we don't
        # want to leak that into the Nix store. As a workaround, we build the
        # image without it (although we still set
        # services.tailscale.authKeyFile), and then have an app that produces as
        # a _runtime_ output a modified image with the key file splatted into
        # it.
        addTailscaleAuthKey = pkgs.writeShellApplication {
          name = "add-tailscale-auth-key";
          runtimeInputs = with pkgs; [ libguestfs-with-appliance zstd ];
          text = ''
          set -eux

          SOURCE_IMG_ZSTD="$1"
          DEST_IMG="$2"
          TS_AUTH_KEY_FILE="$3"

          zstd -d "$SOURCE_IMG_ZSTD" -o "$DEST_IMG"
          chmod +w out.img

          guestfish -a "$DEST_IMG" <<EOF
            run
            mount /dev/sda2 /
            mkdir-p ${builtins.dirOf tailscaleAuthKeyFile}
            upload $TS_AUTH_KEY_FILE ${tailscaleAuthKeyFile}
            umount /
            exit
          EOF
          '';
        };
      };

      apps.x86_64-linux.addTailscaleAuthKey = {
        type = "app";
        program = "${self.packages.x86_64-linux.addTailscaleAuthKey}/bin/add-tailscale-auth-key";
      };

      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [ nixfmt-classic nixos-rebuild libguestfs-with-appliance ];
      };
    };
}
