# NixOS configuration for a Rasperry Pi

Run in a QEMU guest (on x86): `nix run .#nixosConfigurations.sandy.config.system.build.vm`

Build an SD card image: `nix build .#nixosConfigurations.sandy.config.system.build.sdImage`

But, can't run `nixos-rebuild`. AI claims this is because I am importing
`sd-image-aarch64.nix` and I need to separate that out and have separate outputs
for building the SD card image vs for running `nixos-rebuild`. Not sure if I
believe the AI. If I _don't_ import that, I miss all the nice stuff that
configures bootloaders etc.

This also requires compiling the whole world, not sure why that is. It might be
that cross-compilation changes the build hashes so I can't use the ones from the
public caches? But, I dunno.