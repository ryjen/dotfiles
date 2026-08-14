# Optional Home Manager tools

Optional tools are disabled by default and can be enabled from a Home Manager profile.

## Grimblast

Install the Hyprland-native Grimblast screenshot helper with:

```nix
dotfiles.grimblast.enable = true;
```

The module installs `pkgs.grimblast` into the user environment.

## Unreal Editor

Unreal Editor support is intentionally disabled by default. Enable the launcher,
installer helper, and desktop entry with:

```nix
dotfiles.unreal.enable = true;
```

The Unreal Engine payload itself is not committed to dotfiles or copied into the
Nix store. Epic's Linux installed builds require an authenticated Epic Games
download and are large mutable archives. After enabling the module, download the
Linux installed-build ZIP from Epic and install it with:

```bash
unreal-install ~/Downloads/Linux_Unreal_Engine_5.8.zip
```

The portable module default is `$XDG_DATA_HOME/unreal-engine`. The Dubnium
profile overrides only the destination to `/mnt/isotope/Unreal/5.8` so the large
mutable engine tree stays off the root filesystem; it does not enable Unreal.
The helper refuses to replace an existing installation and validates that the
archive contains `Engine/Binaries/Linux/UnrealEditor` before publishing the
directory. To keep multiple versions on another profile, choose a distinct root
in local Home Manager config:

```nix
dotfiles.unreal = {
  enable = true;
  engineRoot = "/path/to/Unreal/5.8";
};
```

Launch the editor from the desktop entry or with:

```bash
unreal-editor
```

The launcher exports `UE_ROOT` and runs the external Epic binary through the
free `steam-run` FHS runtime, providing NixOS compatibility without making the
engine payload or Steam client part of the system closure. Project files and
engine-generated state remain normal mutable user data.

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

The wrapper masks `/run` and selectively restores only the NixOS graphics driver
paths and runtime sockets OpenWork explicitly needs. It exposes Wayland, GPU
acceleration, PipeWire/PulseAudio when present, networking, and a filtered D-Bus
connection limited to desktop portals and notifications. SSH-agent access is
disabled by default.

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
