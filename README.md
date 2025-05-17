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

This also requires compiling the whole world, not sure why that is. It might be
that cross-compilation changes the build hashes so I can't use the ones from the
public caches? But, I dunno.