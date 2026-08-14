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
symlink, and case semantics. Direct NTFS/exFAT/VFAT/CIFS engine and build trees
should therefore be treated as compatibility configurations rather than the
portable default.

### Dubnium isotope-backed storage

Dubnium can keep the large engine, projects, and toolchains physically on the
`/mnt/isotope` drive while exposing them to Unreal through a native ext4
filesystem image:

```text
/mnt/isotope/Unreal/unreal.ext4
             |
             | loop-mounted ext4
             v
/srv/unreal/
├── Engine/
├── Projects/
└── Toolchains/
```

The NixOS storage support is also disabled by default. When dotfiles is consumed
as a flake input, import the exported module into the host's NixOS module list:

```nix
dotfiles.nixosModules.unreal-storage
```

Importing the module alone has no runtime effect. Enable its mount contract
explicitly:

```nix
dubnium.unreal.storage.enable = true;
```

Enabling the module does **not** create or format an image. It adds the guarded
`unreal-storage-init` helper and an ext4 loop mount at `/srv/unreal` using
`loop,noatime,nodev,nosuid,nofail,x-systemd.automount`. The mount declares
`/mnt/isotope` as a dependency path; NixOS resolves whichever configured
filesystem is responsible for that path before attempting the loop mount.

After switching to the configuration, explicitly create an image of the desired
logical capacity:

```bash
sudo unreal-storage-init 500G
```

The initializer:

- refuses to run unless `/mnt/isotope` is an actual mounted filesystem, avoiding
  accidental creation of a huge image on the root filesystem;
- refuses to replace an existing image and uses a no-clobber creation step to
  protect against a concurrent path appearing after the initial check;
- validates that the resolved image parent remains beneath the resolved backing
  mount before creating the image;
- creates and formats only `/mnt/isotope/Unreal/unreal.ext4`;
- rejects a requested logical size larger than the backing filesystem's
  pre-creation available space;
- temporarily loop-mounts the new ext4 filesystem with `nodev,nosuid` to
  establish user ownership and the `Engine`, `Projects`, and `Toolchains`
  directories;
- removes a newly created image if initialization fails and the temporary mount
  can be safely unmounted, but preserves the image if emergency unmount fails;
- warns when the backing filesystem is `ntfs3` without its `sparse` mount option;
- reports the image's actual allocated size with `du` after initialization.

`500G` is only an example. Choose the logical upper bound appropriate for the
isotope drive. With backing-filesystem sparse-file support, physical allocation
can grow as ext4 data is written rather than consuming the complete logical size
immediately. A sparse image is not a capacity boundary for the backing drive:
keep free-space headroom on `/mnt/isotope` and monitor it so the host filesystem
cannot fill while ext4 still believes it has writable blocks.

The Dubnium Home Manager profile selects:

```nix
dotfiles.unreal.engineRoot = "/srv/unreal/Engine/5.8";
```

but does not enable either Unreal or its storage. This keeps the normal machine
configuration unchanged until both features are deliberately selected.

Keep the hot Zen/DDC cache on native system storage by default:

```text
$XDG_CACHE_HOME/unreal-engine/zen
```

The authenticated Epic ZIP and other inert downloads can live directly under
`/mnt/isotope/Unreal/` without requiring POSIX execution semantics.

The Unreal installer refuses to replace an existing engine and validates that
the archive contains `Engine/Binaries/Linux/UnrealEditor` before publishing the
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
a separate writable cache root. The engine directory can be treated as
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
