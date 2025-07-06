# NixOS configuration for a Rasperry Pi

Run in a QEMU guest (on x86): `nix run .#nixosConfigurations.sandy.config.system.build.vm`.
This is surprisingly slow and if I try to `nixos-rebuild` the target I get
"don't know how to build this path" errors that I can't find any online
explanation of. AI gave me an explanation that I don't really believe. Someone
on Discord said they think that you just can't rebuild these NixOS VMs like
that, because of the way their Nix store is set up (it's basically a bind mount
from the host). This latter explanation seems plausible. Anyway, I realised I
can just use "staging" hardware instead.

Build an SD card image: `nix build
.#sdImage`. Or use `.#sdImageStaging`
instead for a test version (just has a different hostname to avoid confusion).

To flash an image that will bring up Tailscale automatically on first boot:

- Build an image as above
- Generate an Auth Key and write it to a file
- Run `nix run .#addTailscaleAuthKey -- $SD_IMAGE_PATH out.img $AUTH_KEY_FILE`
  (where `SD_IMAGE_PATH` is the .img.zst file you built, in the Nix store).
- Flash `out.img` to the SD card.

This dance is because I was too silly to learn a proper way to manage secrets,
maybe `agenix` or `sops-nix` could make this issue go away.

This also requires compiling the whole world, not sure why that is. It might be
that cross-compilation changes the build hashes so I can't use the ones from the
public caches? But, I dunno.

## TODO:

- [ ] Adopt
  [this](https://github.com/femtodata/nix-utils/blob/d18e28bd23f7b6686565ea96a8786fccde12ec13/modules/switch-fix.nix)
  once I can turn my brain on enought to understand it.