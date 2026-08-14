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
download. After enabling the module, download the Linux installed-build ZIP from
Epic and install it with:

```bash
unreal-install ~/Downloads/Linux_Unreal_Engine_5.8.zip
```

The portable engine default is `$XDG_DATA_HOME/unreal-engine`. Choose another
absolute path when the engine should live on a larger native Linux filesystem:

```nix
dotfiles.unreal = {
  enable = true;
  engineRoot = "/data/unreal/5.8";
  cacheRoot = "/data/cache/unreal-engine";
};
```

Prefer a native Linux filesystem for `engineRoot`. A Linux Unreal installation
contains executable toolchains and expects normal POSIX path, permission,
symlink, and case semantics. Do not make NTFS, exFAT, VFAT, CIFS, or another
non-POSIX filesystem the default without validating the actual mount semantics.

The installer refuses to replace an existing engine and validates that the
archive contains `Engine/Binaries/Linux/UnrealEditor` before publishing the
staged directory.

Launch the editor from the desktop entry or with:

```bash
unreal-editor
```

The launcher exports `UE_ROOT` and runs the external Epic binary through the
free `steam-run` FHS runtime, providing NixOS compatibility without making the
engine payload or Steam client part of the system closure.

Epic's Installed Build deployment model is intentionally compatible with a
read-only engine distribution. The wrapper therefore keeps Zen/DDC mutation in
a separate writable cache root, defaulting to
`$XDG_CACHE_HOME/unreal-engine/zen`. The engine directory can be treated as
immutable after installation as long as workflows that intentionally modify the
engine are handled separately.

The important write boundaries are:

- Projects must stay writable. Unreal writes project content and configuration,
  plus generated `Saved`, `Intermediate`, `Binaries`, shader, cooking, autosave,
  and log state.
- Engine-level plugin installation writes under `Engine/Plugins` and therefore
  conflicts with a sealed read-only engine tree. Prefer project-local plugins
  under `<Project>/Plugins` when possible, or deliberately unseal/install/reseal
  an engine version.
- C++ development requires Epic's supported Linux clang/native toolchain in
  addition to this editor wrapper. `SetupToolchain.sh` is a separate setup step
  and may need writable engine/toolchain storage while it runs.
- Fab project content can be imported into a writable project. Fab's documented
  launcher-based `Install to Engine` plugin workflow is Windows/macOS-oriented,
  so Linux engine-plugin installation is less integrated.
- Engine updates are deliberately side-by-side/manual: download a new installed
  build and point `engineRoot` at it rather than mutating an existing version in
  place.

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
