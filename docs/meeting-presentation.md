# Meeting Presentation Workflow

Operator runbook for the Dubnium meeting and presentation workspace session.

## Ownership Boundaries

- **Generated meeting fragment** (`hypr/managed.d/meeting.conf`): owned by
  `modules/home/meeting.nix`. Do not edit manually; changes are overwritten
  on activation.
- **OBS immutable templates** (`files/home/.local/share/dubnium/obs/v1/`):
  shipped by the NixOS module and installed via `xdg.dataFile`. The executor
  copies them into the live OBS profile on first `configctl init apply
  obs-presentation`.
- **Waybar rendered config**: owned by `modules/home/waybar.nix`. Templates in
  `files/home/.config/waybar/` contain placeholders; the rendered JSON is
  generated at activation.
- **Mako config**: `files/home/.config/mako/config` contains the
  `[mode=dubnium-meeting]` section that hides notifications during meeting
  mode.
- **Lifecycle helper**: `files/home/.local/libexec/dubnium-meeting-mode`
  manages Mako mode, cliphist state, and presentation output workspace.
- **Normal user config**: files in `files/home/.config/hypr/adopted.d/`,
  `custom.d/`, and `~/.local/bin/` are user-owned and may be customized.

## Safety Guarantees

- Meeting mode is fail-closed: any start/stop error leaves
  `phase=recovery-needed` in the journal and requires explicit recovery.
- Clipboard history is blocked during meeting mode; cliphist is stopped before
  any Mako mode change.
- Presentation output receives only the constant Waybar presentation bar; no
  Eww overlay opens there.
- No `exec` or `exec-once` directives are generated in the meeting fragment.
- OBS templates contain no machine-local camera identifiers, URLs, tokens, or
  stream keys.

## One-Display Workflow

On a single-monitor setup (no `presentationOutput` configured):

1. Toggle the meeting special workspace with `SUPER+G`.
2. Move windows into the special workspace with `SUPER+SHIFT+G`.
3. OBS scene switching uses `SUPER+CTRL+1/2/3`.
4. Presentation output mapping is not configured; the special workspace is
   visible on the only display.

## Two-Display Workflow

With `dotfiles.meeting.presentationOutput = "DP-1"`:

1. `SUPER+P` moves focus to the presentation workspace on DP-1.
2. `SUPER+SHIFT+P` moves the focused window to the presentation workspace.
3. `SUPER+G` toggles the meeting special workspace (private on any output).
4. `SUPER+SHIFT+G` moves a window into the meeting special workspace.
5. OBS scenes switch with `SUPER+CTRL+1/2/3`.

The presentation workspace on DP-1 shows only the constant Waybar bar and
whatever window is placed there. Normal Waybar is absent from that output.

## hyprctl Monitors/Clients Troubleshooting

```bash
# List active monitors and their connectors
hyprctl monitors -j

# List all clients with class, title, and workspace
hyprctl clients -j

# Filter for Zoom/Teams
hyprctl clients -j | jq '.[] | select(.class | test("zoom|Zoom|firefox|edge"; "i"))'
```

## Meeting Start/Status/Stop

```bash
# Start meeting mode (Mako hidden, cliphist stopped)
systemctl --user start dubnium-meeting-mode.service

# Check status
systemctl --user status dubnium-meeting-mode.service

# Stop meeting mode (Mako restored, cliphist restarted)
systemctl --user stop dubnium-meeting-mode.service
```

The service is `Type=oneshot` with `RemainAfterExit=true`. Start runs
`dubnium-meeting-mode start`; stop runs `dubnium-meeting-mode stop`.

## Notification and Clipboard Behavior

- **Notifications**: Mako enters `dubnium-meeting` mode on start, which sets
  `invisible=1`. All notifications are suppressed. On stop, the previous Mako
  mode is restored.
- **Clipboard history**: cliphist (`wl-paste --watch cliphist store`) is
  stopped before Mako mode change and restarted after. Clipboard picker (wofi
  or rofi) is blocked during meeting mode via the clipboard gate.

## Tier 1: Phone Participant

For a phone-based participant (no screen share, no camera):

1. Start meeting mode.
2. The phone audio authority is the single source of audio.
3. OBS is not required; use `SUPER+G` for the private meeting workspace.
4. Normal Waybar remains on all outputs.

## Tier 2: Host-Provided UVC Camera

For a host-provided USB video class camera:

1. Start meeting mode.
2. Select the camera device in `user.local.nix`:
   ```nix
   dotfiles.meeting.cameraDevice = "/dev/video0";
   ```
3. Run `configctl init apply obs-presentation` to install the OBS profile
   with the camera device injected.
4. Use `SUPER+CTRL+3` to toggle the camera overlay in OBS.
5. Use `SUPER+CTRL+1` for code-only scene, `SUPER+CTRL+2` for code+camera.

## Tier 3: Explicit OBS Setup

For a full OBS presentation setup:

1. Start meeting mode.
2. Apply the OBS init contract:
   ```bash
   configctl init apply obs-presentation --allow mutable-user-state --yes
   ```
3. Verify the profile and collection are installed:
   ```bash
   configctl init verify obs-presentation --json
   ```
4. OBS scene switching: `SUPER+CTRL+1` (code only), `SUPER+CTRL+2`
   (code+camera), `SUPER+CTRL+3` (camera toggle).
5. The presentation output (DP-1) receives only the Waybar presentation bar.

## Normal Stop

```bash
systemctl --user stop dubnium-meeting-mode.service
```

This restores Mako mode, restarts cliphist, and clears the presentation
output workspace mapping. No OBS state is modified.

## Stale Recovery

If meeting mode was interrupted (e.g., crash, power loss):

```bash
# Check the session doctor
dub-session-doctor

# Manually recover
dubnium-meeting-mode recover
```

Recovery requires `systemctl` to query cliphist state. If `systemctl` is
unavailable, recovery fails closed with `phase=recovery-needed`.

## Pre-Interview Checklist

- [ ] **Echo**: Test audio with a colleague before the interview.
- [ ] **Readability**: Ensure terminal font size is adequate for screen share.
- [ ] **Framing**: Check camera framing with `SUPER+CTRL+2`.
- [ ] **Notifications**: Verify Mako is in `dubnium-meeting` mode (no popups).
- [ ] **Waybar**: Confirm normal Waybar is absent from the presentation output.
- [ ] **Eww overlay**: Confirm Eww does not open on the presentation output.
- [ ] **Clipboard UI**: Verify clipboard picker is blocked during meeting mode.
- [ ] **Accidental disclosure**: Check `hyprctl clients -j` for stray windows
  on the presentation output.
- [ ] **OBS scenes**: Verify `SUPER+CTRL+1/2/3` switches scenes correctly.
- [ ] **Meeting mode off**: Run `systemctl --user stop
  dubnium-meeting-mode.service` after the interview.

## Interactive Verification

Actual Zoom/Teams/OBS `class` and `title` values must be checked interactively
on the target system. The default regex patterns in `meeting.nix` are
placeholders:

```nix
teamsClassRegex = "^(firefox|Microsoft-edge|microsoft-edge)$";
teamsTitleRegex = "^Microsoft Teams.*$";
```

If the actual class or title differs, adjust the values in `user.local.nix`:

```nix
dotfiles.meeting.teamsClassRegex = "^(your-actual-class)$";
dotfiles.meeting.teamsTitleRegex = "^(your-actual-title)$";
```

## Special Workspace Privacy Note

The meeting special workspace (`special:meeting`) is **not inherently private**.
It is visible on whichever output has focus when toggled with `SUPER+G`. On a
two-display setup, ensure sensitive windows are moved to the special workspace
from the private output, not the presentation output.
