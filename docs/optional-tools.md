# Optional Home Manager tools

Optional tools are disabled by default and can be enabled from a Home Manager profile.

## Grimblast

Install the Hyprland-native Grimblast screenshot helper with:

```nix
dotfiles.grimblast.enable = true;
```

The module installs `pkgs.grimblast` into the user environment.

## OpenWork

Install the OpenWork desktop application with:

```nix
dotfiles.openwork.enable = true;
```

The module installs a fixed OpenWork AppImage version through a Nix derivation.
The version, upstream release URL, and content hash are committed under
`packages/openwork.nix`; upgrades therefore require an explicit dotfiles change
and rebuild rather than a network-backed first launch.

The module also installs a desktop entry and registers it as the default handler
for `openwork://` links.
