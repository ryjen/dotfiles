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

OpenWork runs in a Bubblewrap sandbox by default. Its private home is persisted
under `$XDG_DATA_HOME/openwork-sandbox/home`; the real home directory, `/root`,
`/mnt`, `/media`, temporary files, system secret directories, and unrelated
user-session sockets are hidden. The host environment is cleared before launch,
so shell API tokens and other inherited credentials are not exposed.

The wrapper exposes Wayland, GPU acceleration, PipeWire/PulseAudio when present,
networking, and a filtered D-Bus connection limited to desktop portals and
notifications. SSH-agent access is disabled by default.

No project directory is exposed unless it is explicitly declared:

```nix
dotfiles.openwork.sandbox = {
  workspacePaths = [
    "${config.home.homeDirectory}/Projects"
  ];
  allowNetwork = true;
  allowSshAgent = false;
};
```

Workspace paths must be beneath the user's home directory and are mounted
read-write at the same path inside the sandbox. Disable the sandbox only for
troubleshooting with `dotfiles.openwork.sandbox.enable = false`.

The module also installs a desktop entry and registers it as the default handler
for `openwork://` links.
