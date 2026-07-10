# Optional Home Manager tools

Optional tools are disabled by default and can be enabled from a Home Manager profile.

## Grimshot

Install the Grimshot screenshot helper with:

```nix
dotfiles.grimshot.enable = true;
```

The module installs `pkgs.sway-contrib.grimshot` into the user environment.
