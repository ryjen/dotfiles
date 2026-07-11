# Optional Home Manager tools

Optional tools are disabled by default and can be enabled from a Home Manager profile.

## Grimblast

Install the Hyprland-native Grimblast screenshot helper with:

```nix
dotfiles.grimblast.enable = true;
```

The module installs `pkgs.grimblast` into the user environment.
