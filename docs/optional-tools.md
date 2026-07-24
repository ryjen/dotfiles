# Optional Home Manager tools

Optional tools are disabled by default and can be enabled from a Home Manager profile.

## Grimblast

Install the Hyprland-native Grimblast screenshot helper with:

```nix
dotfiles.grimblast.enable = true;
```

The module installs `pkgs.grimblast` into the user environment.

## OpenWork

Install the OpenWork desktop launcher with:

```nix
dotfiles.openwork.enable = true;
```

The module installs `appimage-run`, an `openwork` launcher, an explicit
`openwork-update` command, and a desktop entry. The first launch downloads the
latest upstream x86_64 AppImage when no cached version exists. Later upgrades
remain explicit through `openwork-update`.

Downloads are accepted only from the `different-ai/openwork` GitHub release
path and must match the SHA-256 digest published in GitHub's release metadata.
Versioned AppImages are retained under
`$XDG_DATA_HOME/openwork/releases/`, with `OpenWork.AppImage` pointing to the
active version.
