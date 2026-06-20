# dotfiles

Nix-first dotfiles for NixOS and Home Manager with a reusable baseline and opt-in host/profile overlays.

## Layout

- `flake.nix` defines the NixOS and Home Manager entrypoints.
- `hosts/nixos/` contains the current NixOS host config.
- `home/USERNAME/home.nix` is the user Home Manager entrypoint.
- `home/USERNAME/profiles/` contains host/profile selections for a concrete machine.
- `modules/nixos/` contains system modules.
- `modules/home/` contains user modules.
- `files/home/` contains static user config files managed by Home Manager.
- `files/system/` contains static system files used by NixOS modules.

## Profiles

Shared baseline modules are always imported. Host- or organization-specific behavior is enabled through `dotfiles.profiles.*` options from a profile file such as `home/USERNAME/profiles/nixos.nix`.

Current overlays:

- `dotfiles.profiles.workstation.enable` for local workstation session state and PATH additions
- `dotfiles.profiles.android.enable` for Android tooling
- `dotfiles.profiles.micrantha.enable` for Micrantha SSH, Git, and Zsh config

Tracked profile entrypoints:

- `home/USERNAME/profiles/nixos.nix` for the full local machine profile
- `home/USERNAME/profiles/verify.nix` for lightweight verification without Android or other machine-specific overlays
- `modules/home/verify.nix` for the lightweight shared module set used by verification

Architecture rationale lives in `docs/architecture/adr-0001-baseline-and-overlays.md`.

The layered home configuration contract lives in `docs/architecture/home-layering-contract.md`.

Npm global tooling and package promotion are documented in `docs/npm-global-tooling.md`.

## Hyprland and Waybar ownership

Hyprland and Waybar are managed as a session UX substrate rather than loose rice files.

Ownership model:

- Home Manager owns generated base files under `~/.config/hypr` and `~/.config/waybar`.
- `dotfiles.hypr.adoptedProfile` selects machine profile content embedded into generated `~/.config/hypr/hyprland.conf`.
- `~/.config/hypr/adopted.d/machine.conf` is retained for adopted/archive visibility but is not sourced during normal Hyprland load.
- `~/.config/hypr/local.conf` is writable machine-local state and should not be auto-promoted.
- `~/.config/hypr/custom.d/*.conf` is the promotion staging area for user-authored Hyprland fragments.
- `~/.config/waybar/custom.css` is the local stylesheet hook for Waybar experiments.
- Runtime logs and state belong under XDG state/cache locations, not managed config files.

Stable session wrappers are installed into `~/.local/bin`:

- `dub-terminal` launches the configured terminal.
- `dub-launch` launches the configured app launcher.
- `dub-browser` launches the configured browser.
- `dub-file-manager` launches the configured file manager.
- `dub-editor` launches the configured graphical editor.
- `dub-clipboard` opens clipboard history through `cliphist` and a launcher.
- `dub-waybar-reload` restarts Waybar safely.
- `dub-screenshot` wraps `grim`, `slurp`, and `wl-copy` screenshot flows.
- `dub-session-start` starts Waybar, applets, wallpaper, notifications, clipboard history, and optional Eww state with logging.
- `dub-session-reset` restarts the lightweight session services.
- `dub-session-doctor` checks common Hyprland/Waybar recovery issues.

Useful Dubnium bindings:

- `SUPER+Enter`: terminal
- `SUPER+R`: launcher, via physical keycode
- `SUPER+B`: browser
- `SUPER+C`: editor
- `SUPER+D`: file manager
- `SUPER+V`: clipboard history
- `SUPER+Shift+V`: toggle floating
- `SUPER+Z`: resize submap
- `SUPER+W`: move submap
- `SUPER+Shift+R`: reload Waybar
- `SUPER+Shift+Escape`: reset session services
- `Print`: screenshot screen
- `Shift+Print`: screenshot area
- `Ctrl+Shift+Print`: screenshot area to clipboard

Run the session doctor after activation or when Hyprland behaves unexpectedly:

```bash
dub-session-doctor
```

Session startup logs are written to:

```text
~/.local/state/dubnium/session-start.log
```

## Recovery

If Hyprland fails to start or keybindings break:

1. Switch to a TTY.
2. Run `dub-session-doctor`.
3. Inspect `~/.local/state/dubnium/session-start.log`.
4. Temporarily disable local overrides:

   ```bash
   mv ~/.config/hypr/custom.d ~/.config/hypr/custom.d.disabled
   ```

5. Re-apply Home Manager or the Dubnium profile.

## Commands

View flake outputs:

```bash
nix flake show
```

Check evaluation:

```bash
nix flake check --no-build
```

Verify session files:

```bash
nix run .#verify-session-files
```

Verify npm global environment files:

```bash
bash scripts/verify-npm-global-env.sh
```

Apply Home Manager:

```bash
home-manager switch --flake .#USERNAME@nixos
```

Apply NixOS:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

Build Home Manager activation package:

```bash
nix build .#homeConfigurations.USERNAME@nixos.activationPackage
```

Build NixOS system derivation:

```bash
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

Containerized verification:

```bash
nix run .#verify-container
```

Lightweight verification outputs:

```bash
nix flake check --no-build
```
