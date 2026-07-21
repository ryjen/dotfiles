# Meeting Presentation Session Design

## Status

Approved design for [dotfiles#107](https://github.com/ryjen/dotfiles/issues/107).

## Purpose

Provide a declarative user-session layer for private meeting controls and a
deliberately shared code-presentation surface under Hyprland. The baseline must
work without OBS or camera hardware, and no workflow may silently activate a
camera, microphone, recording, or stream.

## Ownership Boundary

This repository owns Home Manager options, Hyprland workspaces and rules, OBS
templates, user-session privacy state, user-visible meeting status, and the
interactive workflow documentation.

The related `ryjen/dubnium#327` issue owns application packages, PipeWire and
portal prerequisites, kernel modules, device discovery, host diagnostics, and
the public `dubctl meeting ...` commands. Dotfiles may provide internal helpers
and a systemd user unit for those commands to invoke, but will not introduce a
separate public `meetingctl` command.

The OBS `configctl init` contract and templates remain dotfiles-owned policy.
Because the `configctl` executor is implemented in Dubnium, enabling that
contract requires a coordinated narrow `obs-presentation` handler under
`ryjen/dubnium#327`; dotfiles must not publish an enabled contract that its
executor cannot handle.

## Home Manager Module

Add a focused `modules/home/meeting.nix` module and import it from the module
registry. The module exposes this supported local configuration surface:

- `dotfiles.meeting.enable`: enable the user-session feature.
- `dotfiles.meeting.presentationOutput`: nullable Hyprland output name.
- `dotfiles.meeting.cameraDevice`: nullable OBS camera device identifier.
- `dotfiles.meeting.teamsClassRegex` and
  `dotfiles.meeting.teamsTitleRegex`: browser or PWA match expressions with
  shared defaults that local configuration can override.

Graphical workstation profiles enable the feature with `lib.mkDefault`.
Hardware-specific output and camera values belong in host overlays or ignored
`user.local.nix` state. The options and placeholders are listed in
`home/ryjen/user.example.nix`.

The module owns generated configuration, internal wrappers, user services, and
assertions. It does not install Zoom, a browser, OBS, camera support, or
host-level diagnostics.

## Hyprland Workspace Contract

Generate one shared meeting fragment and source it after the selected adopted
profile but before writable `local.conf` and `custom.d` fragments. This avoids
duplicating rules across the Dubnium and Technetium adopted profiles while
retaining local override authority.

The fragment defines:

- `special:meeting` for Zoom or Teams controls, OBS controls, and private notes.
- `name:presentation` for explicitly selected shared content.
- `SUPER+G` to toggle or focus the meeting workspace.
- `SUPER+P` to focus the presentation workspace.
- Shift variants to move the active window to the corresponding workspace.
- Ordered rules for native Zoom, Teams browser or PWA windows, the OBS main
  window, and OBS fullscreen projector windows.

Both adopted profiles currently use physical `SUPER+P` (`code:33`) for
pseudotiling. Move that existing action to `SUPER+CTRL+P` before adding the
presentation binding; duplicate dispatches are not acceptable.

The broad existing Firefox rule must not override a more specific Teams rule.
Rules use observed class and title values documented through `hyprctl clients`;
the Teams expressions remain configurable because browser identities vary.

When `presentationOutput` is set, `name:presentation` is pinned to that output.
When it is null, the workspace and bindings remain available but Hyprland
chooses placement. No external output is auto-detected, and no virtual output is
created.

## OBS Templates And Controls

Store a versioned 1920x1080 profile and scene-collection template under
`files/home/.local/share/dubnium/obs/`. Do not symlink templates directly over
OBS mutable configuration.

An explicit `configctl init` contract installs the profile and collection into
OBS state. Installation is idempotent and atomic, refuses to overwrite an
existing profile or collection unless replacement is explicitly requested, and
creates a recoverable backup before replacement. Home Manager activation never
rewrites OBS mutable state.

The collection contains:

- `Code Only`, containing a disabled PipeWire screen-capture placeholder without
  a camera.
- `Code + Camera`, containing the same disabled screen-capture placeholder and a
  camera overlay.

The operator explicitly selects the intended screen or window through OBS and
enables the placeholder before presenting. The templates do not persist a
private display or window selection.

If `cameraDevice` is null, setup leaves the camera source unconfigured and
disabled. If a device is supplied from local configuration, setup substitutes
that identifier but still leaves the camera source disabled. The templates
contain no microphone source, private browser source, secret-bearing path, or
automatic output action.

OBS template hotkeys select either scene and toggle camera-overlay visibility.
Hyprland uses `SUPER+CTRL+1`, `SUPER+CTRL+2`, and `SUPER+CTRL+3`, respectively,
to relay those hotkeys only to an already-running OBS main window. If OBS is
absent, the binding reports a clear no-op. It never launches OBS or starts
recording, streaming, virtual-camera output, camera capture, or microphone
capture. Window rules keep OBS controls on `special:meeting` and send only
fullscreen projector windows to `name:presentation`.

## Meeting Mode Lifecycle

Declare `dubnium-meeting-mode.service` as a `Type=oneshot`,
`RemainAfterExit=yes` systemd user unit. The eventual `dubctl meeting start` and
`dubctl meeting stop` commands invoke this unit. Internal start, stop, status,
and recovery helpers are implementation details rather than a second public
CLI.

Start performs only reversible session changes:

1. Acquire a lock and return success if meeting mode is already active.
2. Record prior state under `$XDG_STATE_HOME/dubnium/meeting/`.
3. Activate a dedicated Mako notification-suppression mode.
4. Stop cliphist capture if it was running and mark the clipboard picker as
   blocked.
5. Activate meeting indicators on the sanitized presentation bar and private
   bars.
6. Publish active status and signal Waybar to refresh.

Stop reverses only state owned by the active meeting session:

1. Acquire the same lock and return success if no owned state exists.
2. Remove the dedicated Mako mode only when start added it.
3. Restart cliphist capture only when it was active before start.
4. Unblock the clipboard picker and clear the meeting indicators.
5. Remove owned state after restoration succeeds and refresh Waybar.

Start and stop are idempotent. Partial command failures are reported and leave
enough state for a subsequent stop or recovery operation. Recovery uses the
same restoration path after abnormal termination or stale state. Starting the
mode does not open workspaces, applications, capture devices, recordings, or
streams.

## Clipboard And Notifications

Move cliphist capture from `dub-session-start` into a dedicated systemd user
service. Meeting mode can then stop it safely and restore it according to its
prior active state. The existing `dub-clipboard` entrypoint checks the meeting
state marker and refuses to display history while mode is active. Existing
history is neither deleted nor displayed.

Add a dedicated Mako mode that suppresses presentation-time notifications.
Meeting mode records whether that mode was already active and does not remove
pre-existing user suppression on stop.

## Waybar And Overlay Privacy

When `presentationOutput` is configured, the normal Waybar configuration always
excludes that output. A second always-sanitized bar assigned only to the
presentation output contains the presentation workspace and meeting-state
indicator. It contains no window title, media metadata, music status, clock,
clipboard content, or hardware telemetry. Meeting mode changes the indicator,
not which bar owns the output.

Private-output bars gain a `custom/meeting` module that is visible only while
meeting mode is active. The Eww quote overlay is constrained to a private output
so it cannot appear on the shared surface. If no presentation output is
configured, the existing normal bar remains authoritative and the private
meeting indicator still works.

## Data And Control Flow

Home Manager evaluates local options into immutable managed fragments,
templates, helper paths, and unit definitions. `configctl init` is the only path
that materializes the OBS templates into mutable application state. At runtime,
`dubctl` asks systemd to start or stop meeting mode; systemd invokes the
dotfiles-owned helper; the helper records XDG state and controls Mako, cliphist,
and Waybar. Hyprland bindings independently navigate workspaces or relay safe
OBS hotkeys.

No runtime helper edits Home Manager-owned files. No hardware identifier is
committed, and camera hardware is not required for evaluation or tests.

## Error Handling And Recovery

- Missing optional OBS, Mako, Waybar, cliphist, or camera capabilities produce
  explicit degraded behavior rather than blocking the baseline workspace flow.
- Invalid configured output names are surfaced by a status or validation helper
  and documented; they do not trigger automatic output selection.
- Runtime state writes are atomic and protected by a lock.
- Stop preserves state when restoration is incomplete so recovery can retry.
- The runbook documents the systemd stop and recovery commands for stale mode.
- Template installation preserves existing mutable OBS state by default.

## Validation

Add mocked helper tests covering:

- start, repeated start, stop, and repeated stop;
- prior Mako suppression and cliphist active-state preservation;
- absent Mako, Waybar, cliphist, OBS, camera hardware, and presentation output;
- partial start failure and stale-state recovery;
- clipboard-picker blocking while active;
- guarantees that no capture or output command is invoked.

Extend static session verification to check:

- both Hyprland profiles source the managed meeting fragment;
- new bindings do not conflict with existing bindings;
- OBS JSON and generated templates parse;
- normal and presentation Waybar JSONC configurations parse;
- required helpers, unit files, and configctl contracts are installed.

Run `nix flake check --no-build`, the focused helper/static tests, and
`nix build .#homeConfigurations.ryjen@dubnium.activationPackage`. Also evaluate
the Technetium Home Manager target so both adopted Hyprland profiles and Waybar
variants remain covered. Interactive validation on a two-display Hyprland
session remains required before claiming the complete workflow works.

## Documentation

Add `docs/meeting-presentation.md` with:

- the dotfiles and Dubnium ownership boundary;
- expected private and presentation workspace behavior on one or two displays;
- Zoom, Teams, and OBS rule troubleshooting with `hyprctl clients`;
- Tier 1 phone-as-second-participant workflow and echo avoidance;
- Tier 2 host-provided USB UVC camera selection;
- Tier 3 OBS template setup, scene selection, and projector workflow;
- normal stop and abnormal recovery procedures;
- a pre-interview checklist for code readability, camera framing, audio echo,
  notifications, Waybar content, clipboard UI, and accidental disclosure.

## Delivery Slices

1. Workspace contract: module options, shared Hyprland fragment, rules, bindings,
   output mapping, static checks, and initial documentation.
2. OBS templates: profile and collection assets, configctl initialization,
   the coordinated Dubnium executor handler, scene and overlay controls, and
   hardware-absent tests.
3. Privacy lifecycle: systemd services, Mako state, cliphist pause and picker
   gate, dual Waybar behavior, status, recovery, and mocked tests.
4. Workflow validation: complete runbook, smoke-test checklist, Nix evaluation
   and builds, and interactive two-display validation notes.

Each slice must remain independently reviewable and testable. The final slice
does not weaken the acceptance criteria of earlier slices.
