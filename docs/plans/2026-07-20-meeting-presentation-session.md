# Meeting Presentation Session Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add private meeting controls, a presentation-only Hyprland workspace, reproducible OBS scenes, and reversible session privacy controls for dotfiles#107.

**Architecture:** A focused Home Manager module generates the shared Hyprland and machine-local inputs while immutable assets remain under `files/home`. A systemd user service owns reversible Mako and cliphist state, Waybar permanently isolates the configured presentation output, and a coordinated Dubnium `configctl` handler safely initializes mutable OBS state.

**Tech Stack:** Nix/Home Manager, Hyprland, Bash, systemd user units, Waybar JSONC, Mako, OBS scene JSON/INI, Python 3.12 standard library, `configctl`.

## Global Constraints

- Baseline Zoom or Teams use must not require OBS or camera hardware.
- No command may silently start OBS, camera capture, microphone capture, recording, streaming, virtual-camera output, or screen capture.
- Do not install host packages, portals, kernel modules, or device-discovery logic in dotfiles.
- Keep real output names and camera identifiers in ignored `user.local.nix` or host overlays.
- Home Manager must not rewrite mutable OBS runtime state; only explicit `configctl init` may initialize or replace it.
- `special:meeting` is private controls and notes; `name:presentation` contains only explicitly selected shared content.
- The normal Waybar must always exclude a configured presentation output.
- Start, stop, and recovery must be idempotent and preserve prior Mako and cliphist state.
- Use `SUPER+CTRL+P` for pseudotiling after reserving `SUPER+P` for presentation.
- Use `path:$PWD` for Nix commands while new files are untracked.
- Do not commit unless the user explicitly requests it. Commit commands below are suggested review checkpoints and must otherwise be skipped.

## File Structure

Dotfiles repository (`external/dotfiles`):

- `modules/home/meeting.nix`: meeting options, generated Hyprland fragment, OBS setup input, helpers, and systemd units.
- `modules/home/waybar.nix`: selects and renders workstation/laptop Waybar templates with output isolation.
- `files/home/.local/libexec/dubnium-meeting-mode`: reversible meeting state machine and Waybar status output.
- `files/home/.local/libexec/dubnium-eww-quote-overlay`: fail-closed private-output selection for Eww.
- `files/home/.local/bin/dub-obs-hotkey`: safe OBS hotkey relay to one existing control window.
- `files/home/.local/share/dubnium/obs/v1/`: immutable OBS profile and scene templates.
- `contracts/configctl/init/obs-presentation.toml`: explicit mutable OBS initialization policy.
- `tests/test-meeting-mode.sh`: command-mocked lifecycle, clipboard, Waybar, and Eww tests.
- `tests/test-dub-obs-hotkey.sh`: command-mocked OBS targeting tests.
- `scripts/verify-obs-templates.py`: semantic template safety checks.
- `scripts/verify-session-files.sh`: static ownership, ordering, binding, and generated-file checks.
- `home/ryjen/meeting-verify-home.nix`: deterministic graphical evaluation fixture with presentation output `DP-1` and no camera.
- `docs/meeting-presentation.md`: operator workflow, recovery, and smoke-test checklist.

Dubnium repository (workspace root):

- `scripts/configctl_lib/handlers/obs_presentation.py`: validates, plans, installs, backs up, and verifies OBS state.
- `scripts/configctl_lib/commands/init.py`: adds explicit `--replace` plumbing.
- `checks/configctl-obs-presentation.py`: fixture-backed handler tests without OBS or camera hardware.

---

### Task 1: Meeting Module And Workspace Contract

**Files:**
- Create: `modules/home/meeting.nix`
- Create: `tests/test-meeting-config.py`
- Create: `home/ryjen/meeting-verify-home.nix`
- Modify: `modules/home/default.nix:6-50`
- Modify: `modules/home/hypr.nix:82-108`
- Modify: `home/ryjen/profiles/workstation.nix`
- Modify: `home/ryjen/user.example.nix`
- Modify: `files/home/.config/hypr/adopted.d/dubnium.conf:161-181`
- Modify: `files/home/.config/hypr/adopted.d/technetium.conf:174-190`
- Modify: `contracts/configctl/apps/hypr.toml`
- Modify: `flake.nix:213-218`

**Interfaces:**
- Produces: `dotfiles.meeting.enable :: bool`.
- Produces: `dotfiles.meeting.presentationOutput :: null | string`.
- Produces: `dotfiles.meeting.cameraDevice :: null | string`.
- Produces: `dotfiles.meeting.teamsClassRegex :: string` and `teamsTitleRegex :: string`.
- Produces: `~/.config/hypr/custom.d/meeting.conf` sourced after adopted content and before local/custom content.

- [ ] **Step 1: Write failing static contract tests**

Create `tests/test-meeting-config.py` with `unittest` cases that read repository files and assert:

```python
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MeetingConfigTest(unittest.TestCase):
    def test_module_is_registered_and_enabled_by_workstation(self) -> None:
        registry = (ROOT / "modules/home/default.nix").read_text()
        profile = (ROOT / "home/ryjen/profiles/workstation.nix").read_text()
        self.assertIn("./meeting.nix", registry)
        self.assertIn("dotfiles.meeting.enable = lib.mkDefault true;", profile)

    def test_hypr_source_order(self) -> None:
        source = (ROOT / "modules/home/hypr.nix").read_text()
        adopted = source.index("${managedHyprConfig}")
        meeting = source.index("custom.d/meeting.conf")
        local = source.index("/hypr/local.conf", meeting)
        custom = source.index("custom.d/*.conf", local)
        self.assertLess(adopted, meeting)
        self.assertLess(meeting, local)
        self.assertLess(local, custom)

    def test_super_p_is_reserved_for_presentation(self) -> None:
        for name in ("dubnium.conf", "technetium.conf"):
            source = (ROOT / "files/home/.config/hypr/adopted.d" / name).read_text()
            self.assertNotIn("bind = $mainMod, code:33, pseudo,", source)
            self.assertIn("bind = $mainMod CTRL, code:33, pseudo,", source)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the tests and verify the expected failure**

Run: `python3 -m unittest tests/test_meeting_config.py -v`

Expected: failures for missing `meeting.nix`, missing import/default/source, and the existing `SUPER+P` pseudotile bindings.

- [ ] **Step 3: Implement the option and generated fragment contract**

Create `modules/home/meeting.nix` with newline-safe string types, graphical/systemd assertions, conditional output mapping, and these generated Hyprland semantics:

```nix
workspace = name:presentation, monitor:${cfg.presentationOutput}
bind = SUPER, G, togglespecialworkspace, meeting
bind = SUPER SHIFT, G, movetoworkspace, special:meeting
bind = SUPER, P, workspace, name:presentation
bind = SUPER SHIFT, P, movetoworkspace, name:presentation
```

Emit the workspace line only when `presentationOutput != null`. Define ordered named rules for Zoom, Teams, OBS controls, and `^Fullscreen Projector.*$`, with Teams after the adopted Firefox rule and the projector rule after general OBS controls. Do not emit `exec` directives.

Add `./meeting.nix` to `modules/home/default.nix`, set `dotfiles.meeting.enable = lib.mkDefault true;` in `workstation.nix`, and document every option with placeholders in `user.example.nix`.

Create `home/ryjen/meeting-verify-home.nix` without importing `user.local.nix`:

```nix
{
  username,
  ...
}:
{
  imports = [
    ./layers/graphical.nix
    ./profiles/dubnium.nix
  ];

  dotfiles.meeting.presentationOutput = "DP-1";
  dotfiles.meeting.cameraDevice = null;
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
```

Expose it as `homeConfigurations."${username}@meeting-verify"` in `flake.nix`.

- [ ] **Step 4: Wire the managed fragment and resolve the binding conflict**

In `modules/home/hypr.nix`, source the generated fragment conditionally:

```nix
${managedHyprConfig}

${lib.optionalString config.dotfiles.meeting.enable ''
  source = ${config.home.homeDirectory}/.config/hypr/custom.d/meeting.conf
''}
source = ${config.home.homeDirectory}/.config/hypr/local.conf
source = ~/.config/hypr/custom.d/*.conf
```

Change both adopted profiles from `bind = $mainMod, code:33, pseudo,` to `bind = $mainMod CTRL, code:33, pseudo,`. Update `contracts/configctl/apps/hypr.toml` so `modules/home/meeting.nix` and `custom.d/meeting.conf` are listed and runtime include order is local, custom.

- [ ] **Step 5: Run focused and Nix evaluation checks**

Run:

```bash
python3 -m unittest tests/test-meeting-config.py -v
nix eval --raw "path:$PWD#homeConfigurations.\"ryjen@dubnium\".config.xdg.configFile.\"hypr/custom.d/meeting.conf\".text"
nix eval --raw "path:$PWD#homeConfigurations.\"ryjen@technetium\".config.xdg.configFile.\"hypr/custom.d/meeting.conf\".text"
nix eval --raw "path:$PWD#homeConfigurations.\"ryjen@meeting-verify\".config.xdg.configFile.\"hypr/custom.d/meeting.conf\".text"
```

Expected: unit tests pass; all evaluations contain the bindings and ordered rules, normal graphical targets omit output mapping, and the fixture contains exactly `workspace = name:presentation, monitor:DP-1`.

- [ ] **Step 6: Review checkpoint**

Suggested commit if requested:

```bash
git add modules/home/meeting.nix modules/home/default.nix modules/home/hypr.nix home/ryjen/profiles/workstation.nix home/ryjen/user.example.nix home/ryjen/meeting-verify-home.nix files/home/.config/hypr/adopted.d contracts/configctl/apps/hypr.toml tests/test-meeting-config.py flake.nix
git commit -m "feat(hypr): add meeting workspace contract"
```

### Task 2: OBS Templates And Safe Hotkey Relay

**Files:**
- Create: `files/home/.local/share/dubnium/obs/v1/profile/basic.ini`
- Create: `files/home/.local/share/dubnium/obs/v1/scene-collection.json`
- Create: `files/home/.local/bin/dub-obs-hotkey`
- Create: `scripts/verify-obs-templates.py`
- Create: `tests/test-dub-obs-hotkey.sh`
- Modify: `modules/home/meeting.nix`

**Interfaces:**
- Produces: immutable template root `$XDG_DATA_HOME/dubnium/obs/v1`.
- Produces: generated `$XDG_CONFIG_HOME/dubnium/meeting/obs-init.json` containing only `cameraDevice`.
- Produces: `dub-obs-hotkey code-only|code-camera|camera-toggle`.
- Consumes: Task 1 meeting options and Hyprland fragment.

- [ ] **Step 1: Write the failing semantic template verifier**

Create `scripts/verify-obs-templates.py` using `configparser` and `json`. It must fail unless the profile is 1920x1080, scenes are exactly `Code Only` and `Code + Camera`, all PipeWire and camera scene items start hidden, camera settings contain no device identifier, `saved_projectors` is empty, and source IDs contain none of `audio`, `browser`, `ffmpeg`, or `media`. Reject absolute home paths, `/dev/video`, URLs, tokens, stream keys, and output-start hotkeys.

Run: `python3 scripts/verify-obs-templates.py .`

Expected: FAIL because the templates do not exist.

- [ ] **Step 2: Add portable OBS templates**

Create `basic.ini` with only:

```ini
[General]
Name=Dubnium Presentation

[Video]
BaseCX=1920
BaseCY=1080
OutputCX=1920
OutputCY=1080
FPSType=0
FPSCommon=30
```

Create the scene collection from the host-provided OBS major version, then reduce it to the two required scenes, one shared `pipewire-screen-capture-source`, and one `v4l2_input` named `Camera Overlay`. Keep every screen and camera item `visible: false`, camera settings empty, projector state empty, and embed internal `CTRL+ALT+1/2/3` scene/item hotkeys. The verifier, not byte identity, defines the portable contract.

- [ ] **Step 3: Write failing command-mocked relay tests**

In `tests/test-dub-obs-hotkey.sh`, place a fake `hyprctl` first on `PATH`. Cover no clients, one OBS control window, control plus projector, projector only, two controls, malformed JSON, and dispatch failure. Assert that successful dispatch is exactly one of:

```text
hyprctl dispatch sendshortcut CTRL ALT,1,address:0xCONTROL
hyprctl dispatch sendshortcut CTRL ALT,2,address:0xCONTROL
hyprctl dispatch sendshortcut CTRL ALT,3,address:0xCONTROL
```

Run: `bash tests/test-dub-obs-hotkey.sh`

Expected: FAIL because `dub-obs-hotkey` does not exist.

- [ ] **Step 4: Implement the relay and module wiring**

Implement `dub-obs-hotkey` with `set -euo pipefail`. Accept only the three public actions, query `hyprctl clients -j`, use `jq` to select exactly one `com.obsproject.Studio` non-projector client, refuse ambiguous targeting, and send only the mapped shortcut. An absent OBS control window is a documented no-op; malformed output and dispatch failure are errors. Never invoke an OBS executable or capture command.

Update `meeting.nix` to publish the template tree through `xdg.dataFile`, render `obs-init.json` with `builtins.toJSON { cameraDevice = cfg.cameraDevice; }`, install the helper executable, and add `SUPER+CTRL+1/2/3` Hyprland bindings to invoke it.

- [ ] **Step 5: Verify templates and relay behavior**

Run:

```bash
python3 scripts/verify-obs-templates.py .
bash tests/test-dub-obs-hotkey.sh
python3 -m unittest tests/test_meeting_config.py -v
```

Expected: all checks pass without OBS, a camera, or a display server.

- [ ] **Step 6: Review checkpoint**

Suggested commit if requested:

```bash
git add files/home/.local/share/dubnium/obs files/home/.local/bin/dub-obs-hotkey modules/home/meeting.nix scripts/verify-obs-templates.py tests/test-dub-obs-hotkey.sh tests/test-meeting-config.py
git commit -m "feat(obs): add presentation templates"
```

### Task 3: Dubnium OBS Initialization Executor

**Repository:** `/home/ryjen/.local/src/dubnium`

**Files:**
- Create: `scripts/configctl_lib/handlers/obs_presentation.py`
- Create: `checks/configctl-obs-presentation.py`
- Modify: `scripts/configctl_lib/handlers/__init__.py`
- Modify: `scripts/configctl_lib/commands/init.py:111-121,220-244`
- Modify: `flake.nix` check registration for the new fixture test

**Interfaces:**
- Consumes: init contract kind `obs-presentation`.
- Consumes: `templateProfile`, `templateCollection`, `settings`, `profileTarget`, `collectionTarget`, and `[behavior]` fields.
- Produces: `configctl init apply obs-presentation [--replace]` with atomic per-target writes, rollback, and recoverable backups.

- [ ] **Step 1: Write failing fixture-backed executor tests**

Create `checks/configctl-obs-presentation.py` with temporary XDG directories and a parsed `InitContract`. Test missing-target install, matching-target no-op, existing-target refusal, `--replace` without `destructive` refusal, replacement backup, null/configured camera structural substitution, invalid JSON with no mutation, simulated second-target failure rollback, running-OBS refusal, and verification mismatch reporting.

Run: `python3 checks/configctl-obs-presentation.py`

Expected: FAIL because the handler and `--replace` interface do not exist.

- [ ] **Step 2: Add explicit replacement plumbing**

In `InitCommand.register`, add:

```python
apply_parser.add_argument(
    "--replace",
    action="store_true",
    help="replace existing mutable state when the selected handler supports it",
)
```

Pass `replace=args.replace` from `run_apply` to `handler.apply`. Keep existing `--force` semantics restricted to pip globals.

- [ ] **Step 3: Implement and register `ObsPresentationInitHandler`**

Implement `kind = "obs-presentation"`. Validate all source and destination paths, require destinations beneath `$XDG_CONFIG_HOME/obs-studio/basic/`, parse both JSON inputs structurally, locate `Camera Overlay` by source name and `v4l2_input`, and set `settings["device_id"]` only when the generated settings value is non-null. Never make camera items visible.

For apply, acquire `$XDG_STATE_HOME/configctl/init/obs-presentation/apply.lock`, stage within each destination parent, rename only after validation, and roll back the profile if collection installation fails. Existing targets require `replace=True` and `destructive` in `allow_risks`; create timestamped backups plus a hash manifest before replacement. Refuse replacement while OBS is running. Write state atomically only after success.

Register the handler from `scripts/configctl_lib/handlers/__init__.py`.

- [ ] **Step 4: Run focused and existing configctl checks**

Run:

```bash
python3 checks/configctl-obs-presentation.py
python3 -m unittest discover -s tests -p 'test_configctl*.py'
nix build .#checks.x86_64-linux.configctl-obs-presentation
```

Expected: new and existing configctl checks pass; tests use only temporary files and mocked process state.

- [ ] **Step 5: Review checkpoint**

Suggested Dubnium commit if requested:

```bash
git add scripts/configctl_lib/handlers/obs_presentation.py scripts/configctl_lib/handlers/__init__.py scripts/configctl_lib/commands/init.py checks/configctl-obs-presentation.py flake.nix
git commit -m "feat(configctl): initialize OBS presentation state"
```

### Task 4: Dotfiles OBS Init Contract

**Files:**
- Create: `contracts/configctl/init/obs-presentation.toml`
- Modify: `scripts/verify-configctl-contracts.py`
- Modify: `contracts/configctl/README.md`
- Modify: `contracts/configctl/schema-v1.md`

**Interfaces:**
- Consumes: Task 2 template/settings paths.
- Consumes: Task 3 registered handler.
- Produces: enabled `obs-presentation` init contract with normal risk `mutable-user-state` and opt-in replacement risk enforced by the handler.

- [ ] **Step 1: Add failing contract validation cases**

Extend the verifier to require fixed OBS template roots and targets, `replace = false`, `backupBeforeReplace = true`, `atomicWrite = true`, `refuseWhileObsRunning = true`, and no default `destructive` risk. Add mutations proving it rejects destinations outside OBS basic profile/scenes paths, missing assets, a committed camera identifier, and default replacement.

Run: `python3 scripts/verify-configctl-contracts.py .`

Expected: FAIL because the enabled contract is absent.

- [ ] **Step 2: Add the enabled contract**

Create the contract with:

```toml
schemaVersion = 1
id = "obs-presentation"
kind = "obs-presentation"
enabled = true
risk = ["mutable-user-state"]
profile = "workstation"
tags = ["obs", "meeting", "presentation"]
description = "Install the versioned Dubnium OBS presentation profile and scene collection."

templateProfile = "$XDG_DATA_HOME/dubnium/obs/v1/profile"
templateCollection = "$XDG_DATA_HOME/dubnium/obs/v1/scene-collection.json"
settings = "$XDG_CONFIG_HOME/dubnium/meeting/obs-init.json"
profileName = "Dubnium Presentation"
collectionName = "Dubnium Meeting Presentation"
profileTarget = "$XDG_CONFIG_HOME/obs-studio/basic/profiles/Dubnium Presentation"
collectionTarget = "$XDG_CONFIG_HOME/obs-studio/basic/scenes/Dubnium Meeting Presentation.json"

[behavior]
createIfMissing = true
replace = false
backupBeforeReplace = true
atomicWrite = true
refuseWhileObsRunning = true
```

Document first install and explicit replacement commands, including `--allow mutable-user-state,destructive` for replacement.

- [ ] **Step 3: Verify both sides of the contract**

Run in dotfiles:

```bash
python3 scripts/verify-configctl-contracts.py .
nix build "path:$PWD#checks.x86_64-linux.configctl-contracts"
```

After activating the coordinated Dubnium executor in a disposable XDG fixture, run `configctl init plan obs-presentation`, apply it, verify it, and confirm repeated apply is a no-op.

- [ ] **Step 4: Review checkpoint**

Suggested commit if requested:

```bash
git add contracts/configctl/init/obs-presentation.toml contracts/configctl/README.md contracts/configctl/schema-v1.md scripts/verify-configctl-contracts.py
git commit -m "feat(configctl): declare OBS presentation setup"
```

### Task 5: Reversible Meeting Privacy Lifecycle

**Files:**
- Create: `files/home/.local/libexec/dubnium-meeting-mode`
- Create: `tests/test-meeting-mode.sh`
- Modify: `modules/home/meeting.nix`
- Modify: `files/home/.local/bin/dub-session-start:53-67`
- Modify: `files/home/.local/bin/dub-clipboard:1-6`
- Modify: `files/home/.local/bin/dub-session-doctor`
- Modify: `files/home/.config/mako/config`

**Interfaces:**
- Produces: `dubnium-meeting-mode start|stop|recover|status|status --json|waybar private|waybar presentation|can-capture`.
- Produces: `dubnium-meeting-mode.service` with no `WantedBy` and `RemainAfterExit=true`.
- Produces: `dubnium-cliphist.service` attached to `graphical-session.target`.
- Produces: private state under `${XDG_STATE_HOME:-$HOME/.local/state}/dubnium/meeting`.

- [ ] **Step 1: Write failing lifecycle and clipboard tests**

Create `tests/test-meeting-mode.sh` with temporary HOME/XDG directories and fake `systemctl`, `makoctl`, `hyprctl`, and `pkill` commands. Cover start/repeated start, stop/repeated stop, pre-existing Mako mode, initially inactive cliphist, absent optional tools, partial start, stale recovery, configured output present/absent, clipboard picker blocking before `cliphist list`, parseable Waybar JSON, and traps proving no OBS/audio/video/capture command runs.

Run: `bash tests/test-meeting-mode.sh`

Expected: FAIL because the helper and services do not exist and the clipboard picker is not gated.

- [ ] **Step 2: Implement the fail-closed state machine**

Use `umask 077`, `flock`, same-directory temporary files, and atomic `mv`. State fields are `version`, `phase`, `mako_was_active`, `mako_added`, `cliphist_was_active`, and `cliphist_stopped`; phases are `starting`, `active`, `stopping`, and `recovery-needed`. Persist intent before each side effect. Create the `active` marker before querying clipboard-related state and remove it only after all owned restoration succeeds.

Start adds exact Mako mode `dubnium-meeting` only when absent and stops cliphist only when its unit was active. Stop removes only a mode added by this start and restarts cliphist only when previously active. Optional missing capabilities produce degraded status but keep the service usable. `recover` calls the same restoration path as stop.

Waybar commands emit one JSON object; inactive private output is empty, active/degraded private output is visible, and presentation output always uses constant non-sensitive text. Refresh with `pkill -RTMIN+8 waybar` as a nonfatal operation.

Pass `DUBNIUM_PRESENTATION_OUTPUT` into the unit from the Home Manager option. `status` queries `hyprctl monitors -j` when that value is nonempty and reports a degraded reason when the configured name is not connected; it never chooses a replacement output.

- [ ] **Step 3: Add systemd ownership and remove ad hoc capture**

In `meeting.nix`, install the helper and define:

```nix
systemd.user.services.dubnium-meeting-mode = {
  Unit.Description = "Dubnium meeting privacy mode";
  Service = {
    Type = "oneshot";
    RemainAfterExit = true;
    ExecStart = "%h/.local/libexec/dubnium-meeting-mode start";
    ExecStop = "%h/.local/libexec/dubnium-meeting-mode stop";
  };
};
```

Define `dubnium-cliphist` as a simple service with `ExecCondition = "%h/.local/libexec/dubnium-meeting-mode can-capture"`, `ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store"`, restart-on-failure, and `WantedBy = [ "graphical-session.target" ]`. Gate units on `dotfiles.host.userSystemd.enable` and remove the unmanaged watcher block from `dub-session-start`.

- [ ] **Step 4: Gate clipboard UI and add Mako mode**

At the start of `dub-clipboard`, before dependency checks, exit 75 when `$XDG_STATE_HOME/dubnium/meeting/active` exists. Add to Mako:

```ini
[mode=dubnium-meeting]
invisible=1
```

Update the session doctor to use `systemctl --user is-active` for cliphist and report meeting status without reading sensitive state.

- [ ] **Step 5: Run lifecycle tests**

Run:

```bash
bash tests/test-meeting-mode.sh
bash -n files/home/.local/libexec/dubnium-meeting-mode
bash -n files/home/.local/bin/dub-clipboard
bash -n files/home/.local/bin/dub-session-start
```

Expected: all tests pass and command logs contain no capture/output tool invocation.

- [ ] **Step 6: Review checkpoint**

Suggested commit if requested:

```bash
git add files/home/.local/libexec/dubnium-meeting-mode files/home/.local/bin/dub-session-start files/home/.local/bin/dub-clipboard files/home/.local/bin/dub-session-doctor files/home/.config/mako/config modules/home/meeting.nix tests/test-meeting-mode.sh
git commit -m "feat(session): add reversible meeting privacy mode"
```

### Task 6: Presentation-Safe Waybar And Eww

**Files:**
- Create: `modules/home/waybar.nix`
- Create: `files/home/.local/libexec/dubnium-eww-quote-overlay`
- Modify: `modules/home/default.nix`
- Modify: `modules/home/hypr.nix:110-124`
- Modify: `home/ryjen/profiles/technetium.nix`
- Modify: `files/home/.config/waybar/config.jsonc`
- Modify: `files/home/.config/waybar/config-technetium.jsonc`
- Modify: `files/home/.config/waybar/custom.css`
- Modify: `files/home/.config/eww/eww.yuck`
- Modify: `files/home/.local/bin/dub-session-start:73-79`
- Modify: `files/home/.config/hypr/adopted.d/technetium.conf:227-234`
- Modify: `tests/test-meeting-mode.sh`

**Interfaces:**
- Consumes: `dotfiles.meeting.presentationOutput` and lifecycle Waybar JSON.
- Produces: one multi-bar Waybar configuration; normal bar excludes presentation output and sanitized bar targets only it.
- Produces: Eww wrapper that opens only on a discovered non-presentation output.

- [ ] **Step 1: Add failing generated-config privacy tests**

Extend `tests/test_meeting_config.py` to run `nix eval --raw` for the `ryjen@meeting-verify` Waybar text, parse it with `json.loads`, and assert it has two bars, normal output order `['!DP-1', '*']`, and presentation output `DP-1`. Assert the presentation bar contains only `hyprland/workspaces#presentation` and `custom/meeting#presentation` and none of `window`, `media`, `music`, `clock`, `cpu`, `memory`, `temperature`, `tray`, or audio modules.

Extend `tests/test-meeting-mode.sh` with mocked `hyprctl monitors -j` and `eww`: two displays must select the non-presentation name; a single presentation display must never call `eww open`.

Run both tests and expect failures before implementation.

- [ ] **Step 2: Move Waybar ownership to a focused module**

Move existing Waybar declarations from `hypr.nix` into `waybar.nix`. Select workstation or laptop template through a small enum option rather than `lib.mkForce`; set the laptop variant from `technetium.nix` and remove its direct `xdg.configFile` override.

Render template tokens with `builtins.replaceStrings`: normal outputs are `builtins.toJSON [ "*" ]` when null or `[ "!${output}" "*" ]` when configured; presentation output is a deliberately nonexistent name when null or the configured output otherwise. Keep exclusion before wildcard.

- [ ] **Step 3: Make both templates multi-bar and sanitized**

Convert both JSONC templates to strict JSON arrays so rendered output can be validated with Python's standard `json` module. Preserve each existing normal bar and add `custom/meeting` to its right modules. Add a presentation bar with constant `Presentation` workspace text and only the two approved modules. Do not add click handlers or tooltips. Add `.active`, `.degraded`, and presentation bar styles to `custom.css`.

- [ ] **Step 4: Implement fail-closed Eww placement**

Remove hard-coded `:monitor 0` from `eww.yuck`. The wrapper reads `DUBNIUM_PRESENTATION_OUTPUT`; when unset it retains screen 0, otherwise it selects the first different monitor from `hyprctl monitors -j`. If discovery fails or no private monitor exists, close the overlay and return without opening it. Install a generated launcher from `meeting.nix` that exports the configured output and executes the static wrapper.

Replace direct Eww opens in both startup paths with the wrapper so Dubnium and Technetium share behavior.

- [ ] **Step 5: Run privacy rendering and helper tests**

Run:

```bash
python3 -m unittest tests/test_meeting_config.py -v
bash tests/test-meeting-mode.sh
nix eval --json "path:$PWD#homeConfigurations.\"ryjen@dubnium\".config.xdg.configFile.\"waybar/config.jsonc\".text"
nix eval --json "path:$PWD#homeConfigurations.\"ryjen@technetium\".config.xdg.configFile.\"waybar/config.jsonc\".text"
nix eval --json "path:$PWD#homeConfigurations.\"ryjen@meeting-verify\".config.xdg.configFile.\"waybar/config.jsonc\".text"
```

Expected: tests pass; both rendered configurations are valid JSONC and no presentation bar exposes sensitive modules.

- [ ] **Step 6: Review checkpoint**

Suggested commit if requested:

```bash
git add modules/home/waybar.nix modules/home/default.nix modules/home/hypr.nix home/ryjen/profiles/technetium.nix files/home/.config/waybar files/home/.config/eww files/home/.local/libexec/dubnium-eww-quote-overlay files/home/.local/bin/dub-session-start files/home/.config/hypr/adopted.d/technetium.conf tests
git commit -m "feat(waybar): isolate presentation output"
```

### Task 7: Static Checks, Runbook, And End-To-End Validation

**Files:**
- Modify: `scripts/verify-session-files.sh`
- Modify: `flake.nix:114-188`
- Create: `docs/meeting-presentation.md`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-07-20-meeting-presentation-session-design.md` only if implementation reveals a reviewed design correction

**Interfaces:**
- Consumes: all prior task outputs.
- Produces: flake checks `session-files`, `obs-templates`, `obs-hotkey-helper`, and `meeting-mode-tests`.
- Produces: complete operator workflow and recovery documentation.

- [ ] **Step 1: Extend static verification before wiring checks**

Make `verify-session-files.sh` accept `[repo-root]`, check Bash syntax in both `.local/bin` and `.local/libexec`, and verify both Hyprland profiles, generated module ownership, source/rule order, no duplicate meeting bindings, the `code:33` migration, Mako mode, service declarations, Waybar templates, OBS assets, helpers, contracts, and docs. Delegate semantic OBS checks to `verify-obs-templates.py`; do not parse JSONC with plain `jq` or strip URL-like text blindly.

Run: `bash scripts/verify-session-files.sh "$PWD"`

Expected: PASS only after every prior deliverable exists.

- [ ] **Step 2: Promote focused tests into flake checks**

Wrap the session app so it passes `${self}` explicitly. Add run-command checks with only required native tools:

```nix
session-files = pkgs.runCommand "session-files" {
  nativeBuildInputs = [ pkgs.bash pkgs.python3 ];
} ''
  bash ${./scripts/verify-session-files.sh} ${self}
  touch "$out"
'';
```

Add analogous checks for OBS template verification, the OBS relay shell test, and meeting lifecycle shell test with `bash`, `coreutils`, `jq`, and `util-linux` as needed.

- [ ] **Step 3: Write the operator runbook**

Create `docs/meeting-presentation.md` covering ownership boundaries, safety guarantees, one- and two-display workflows, `hyprctl monitors/clients` troubleshooting, meeting start/status/stop, notification and clipboard behavior, Tier 1 phone participant with one audio authority, Tier 2 host-provided UVC selection, Tier 3 explicit OBS setup and screen/camera enabling, normal stop, stale recovery, and a pre-interview checklist for echo, readability, framing, notifications, bars, clipboard UI, and accidental disclosure.

State that actual Zoom/Teams/OBS class/title values must be checked interactively and local regex options adjusted if defaults do not match. State that a special workspace is not inherently private and must be opened from the private output.

- [ ] **Step 4: Run all noninteractive validation**

Run in dotfiles:

```bash
python3 -m unittest discover -s tests -p 'test_*.py' -v
bash tests/test-dub-obs-hotkey.sh
bash tests/test-meeting-mode.sh
python3 scripts/verify-obs-templates.py .
python3 scripts/verify-configctl-contracts.py .
bash scripts/verify-session-files.sh "$PWD"
nix flake check "path:$PWD" --no-build
nix build "path:$PWD#checks.x86_64-linux.session-files"
nix build "path:$PWD#checks.x86_64-linux.obs-templates"
nix build "path:$PWD#checks.x86_64-linux.obs-hotkey-helper"
nix build "path:$PWD#checks.x86_64-linux.meeting-mode-tests"
nix build "path:$PWD#homeConfigurations.\"ryjen@dubnium\".activationPackage"
nix build "path:$PWD#homeConfigurations.\"ryjen@technetium\".activationPackage"
nix build "path:$PWD#homeConfigurations.\"ryjen@meeting-verify\".activationPackage"
```

Expected: every command exits 0. Report any resource-limited build not run; do not claim it passed.

- [ ] **Step 5: Perform interactive validation before claiming full acceptance**

After `home-manager switch`, validate on two displays:

```bash
hyprctl monitors -j
hyprctl clients -j
systemctl --user status dubnium-cliphist.service
systemctl --user start dubnium-meeting-mode.service
systemctl --user status dubnium-meeting-mode.service
systemctl --user stop dubnium-meeting-mode.service
```

Confirm Zoom/Teams controls stay private, only selected content appears on presentation, normal Waybar is absent there, Eww never opens there, clipboard picker is blocked during mode, notification and cliphist state restore, OBS scenes import/save/reload under the host OBS version, and camera remains hidden until explicitly revealed.

- [ ] **Step 6: Final review checkpoint**

Inspect `git status`, `git diff --check`, and diffs in both repositories. Stage only issue-related files and do not include the pre-existing local `main` commit or ignored machine identifiers.

Suggested dotfiles commit if requested:

```bash
git add flake.nix scripts/verify-session-files.sh docs/meeting-presentation.md README.md docs/superpowers
git commit -m "docs: add meeting presentation workflow"
```
