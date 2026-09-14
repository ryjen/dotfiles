# Camera and Meeting Ownership Design

## Status

Approved architecture for separating host/kernel camera capability from user-owned meeting applications and session UX across `ryjen/dubnium` and `ryjen/dotfiles`.

## Goals

- Remove the artificial `dubnium.videoMeeting` host abstraction.
- Keep host/kernel/platform capability ownership in `ryjen/dubnium`.
- Move user applications such as Zoom and Chromium ownership to `ryjen/dotfiles` / Home Manager.
- Keep meeting/privacy/presentation behavior in `dotfiles.meeting`.
- Rename the Android phone-camera helper to `dubctl-phone-camera` so it is automatically discovered by `dubctl` as `dubctl phone camera ...`.
- Preserve direct execution of `dubctl-phone-camera`.
- Keep Zoom, Teams integration, phone-camera tooling, and meeting UX independently configurable.
- Preserve native Android USB UVC/Webcam mode as the preferred path when available.
- Keep virtual-camera support optional and explicit.

## Non-goals

- Reintroducing a `dubctl meeting` lifecycle command tree.
- Adding a dedicated Teams launcher or PWA wrapper in this change.
- Automatically starting cameras, microphones, OBS, screen capture, recording, or streaming.
- Making v4l2loopback mandatory on graphical hosts.
- Moving PipeWire, portals, Hyprland, or generic browser platform configuration into camera-specific code.
- Adding a new `dubctl camera status` bounded context.

## Ownership Model

### `ryjen/dubnium`

Dubnium owns machine-level capabilities only:

- PipeWire/audio platform capability through existing audio ownership.
- XDG portal and graphical platform capability through existing graphical profile ownership.
- Optional virtual-camera kernel/device capability through a focused camera module.
- Stable host device alias `/dev/dubnium-camera` when the virtual camera is enabled.
- Nix evaluation and host capability tests.

Dubnium no longer owns Zoom, Teams/browser application packages, or meeting-session lifecycle.

### `ryjen/dotfiles`

Dotfiles/Home Manager owns user applications and session behavior:

- Firefox and Chromium user browser packages/profile behavior.
- Zoom user application package.
- Teams-specific window matching/integration.
- Meeting/privacy/presentation workspaces and services.
- OBS user-session integration.
- Android phone-camera producer tooling.
- `dubctl-phone-camera` PATH extension.

## Dubnium Camera Contract

Replace `dubnium.videoMeeting.virtualCamera` with a general-purpose host capability:

```nix
dubnium.camera.virtual = {
  enable = false;
  deviceNumber = 10;
  label = "Dubnium Virtual Camera";
  exclusiveCaps = true;
};
```

The module is not meeting-specific. It may be consumed by scrcpy, OBS, ffmpeg, tests, or other V4L2 producers/consumers.

When enabled, the module must:

- load `v4l2loopback`;
- use exactly one loopback device;
- reserve `video_nr=10` by default;
- set `card_label="Dubnium Virtual Camera"` by default;
- set `exclusive_caps=1` by default;
- set `max_buffers=2`;
- expose `/dev/dubnium-camera` as the stable alias for the configured `/dev/videoN` sink;
- remain opt-in;
- never start a producer.

When disabled, the module must remove only the stable symlink it owns and must never remove an unexpected non-symlink object at `/dev/dubnium-camera`.

Changing module parameters on an already loaded `v4l2loopback` instance may require unloading/reloading the module or rebooting; the runbook must state this explicitly.

## Removal of `video-meeting.nix`

`modules/workloads/video-meeting.nix` should be removed rather than reduced to an unrelated virtual-camera wrapper.

Its current responsibilities move as follows:

| Current responsibility | New owner |
| --- | --- |
| PipeWire prerequisite | existing Dubnium audio/platform modules |
| XDG portal prerequisite | existing graphical profile |
| Zoom package | dotfiles `meeting.nix` |
| Chromium package for Teams | dotfiles `browser.nix` |
| v4l2loopback | focused Dubnium camera module |
| meeting UX/session lifecycle | existing dotfiles `meeting.nix` |

The `dubnium.videoMeeting.*` option namespace is removed after all host references and checks are migrated.

## Dotfiles Browser Contract

`dotfiles.profiles.browser.enable` owns general interactive browsers.

Chromium is treated as a general user browser/package rather than a Teams-specific dependency. The browser profile therefore installs Chromium alongside the existing Firefox ownership and Chromium-backed ChatGPT launcher.

Teams integration must not be responsible for installing Chromium.

## Dotfiles Meeting Contract

Meeting UX remains independently enabled:

```nix
dotfiles.meeting = {
  enable = true;

  zoom.enable = true;
  teams.enable = true;
  phoneCamera.enable = true;
};
```

The option meanings are intentionally independent:

- `meeting.enable`: owns workspace/privacy/presentation behavior and related user services.
- `meeting.zoom.enable`: installs `pkgs.zoom-us` and enables Zoom-specific window rules.
- `meeting.teams.enable`: enables Teams-specific window rules/integration; it does not install a browser.
- `meeting.phoneCamera.enable`: installs Android/ADB/scrcpy/V4L2 dependencies and `dubctl-phone-camera`.

Disabling one application/integration must not disable unrelated meeting/session functionality.

### Teams

No dedicated Teams launcher is added in this change. The user opens Teams normally in the browser. Existing class/title matching is retained behind `meeting.teams.enable`.

`meeting.teams.enable` may assert that the browser profile is enabled if the Home Manager module graph exposes that state reliably. If such an assertion would create an unnecessary cross-profile dependency, the implementation should instead document the dependency and keep the option side-effect free.

### Zoom

`meeting.zoom.enable` controls only the Zoom package and Zoom-specific session/window behavior. Zoom is no longer installed by Dubnium.

## Phone Camera Command Contract

Rename:

```text
dub-phone-camera
```

to:

```text
dubctl-phone-camera
```

The executable is installed on the normal user PATH by Home Manager. The existing PATH-extension resolver then exposes it as:

```bash
dubctl phone camera devices
dubctl phone camera cameras
dubctl phone camera front
dubctl phone camera back
```

Direct execution remains supported:

```bash
dubctl-phone-camera back
```

The command behavior remains:

1. Explicit `DUBNIUM_PHONE_CAMERA_DEVICE` override wins.
2. Prefer verified `/dev/dubnium-camera` when present.
3. Fall back to v4l2loopback sysfs discovery for legacy/custom hosts.
4. Fail with an actionable error if no loopback sink is available.

The producer remains USB-only:

- `scrcpy --select-usb`;
- camera video source;
- explicit `--no-audio`;
- `--no-playback`;
- adaptive/default max size with the existing environment override.

Native Android USB Webcam/UVC mode remains preferred because it requires no v4l2loopback bridge.

## `dubctl` Discovery Contract

The rename is not considered complete solely because a `dubctl-phone-camera` file exists. Tests must exercise actual resolver dispatch:

```bash
dubctl phone camera --version
dubctl phone camera --help
dubctl phone camera devices
```

The packaged/integration test may stub external device commands for deterministic execution, but it must prove that `dubctl` resolves the longest PATH extension to `dubctl-phone-camera` and passes the remaining arguments unchanged.

No `dubctl meeting` command is reintroduced.

## Testing Strategy

### Dotfiles

Tests must cover:

- `dotfiles.meeting.enable` independent of Zoom, Teams, and phone-camera toggles;
- `zoom.enable` installs Zoom only when enabled;
- `teams.enable` gates Teams-specific rules without owning Chromium;
- browser profile owns Chromium;
- `phoneCamera.enable` installs dependencies and `dubctl-phone-camera`;
- old `dub-phone-camera` is absent after migration;
- phone-camera helper discovery precedence remains explicit override -> stable host alias -> legacy sysfs fallback;
- packaged `dubctl phone camera` resolver dispatch works;
- meeting mode never implicitly starts camera, microphone, OBS, recording, streaming, or screen capture.

### Dubnium

Tests must cover:

- camera module defaults off;
- enabling camera adds `v4l2loopback` kernel/module package configuration;
- exact rendered module options include `devices=1`, configured `video_nr`, configured label, `exclusive_caps`, and `max_buffers=2`;
- stable alias points to the configured device;
- disabling the capability removes only the owned stable symlink;
- headless/non-graphical profiles do not gain a virtual camera unless explicitly supported by the final module placement;
- no Zoom or Chromium package is installed through the removed `videoMeeting` abstraction;
- the `dubnium.videoMeeting` namespace and obsolete checks are removed.

## Migration Order

The repositories should be changed in dependency-safe order:

1. Dotfiles: add independent meeting application toggles, move Chromium/Zoom ownership, and rename the phone-camera helper to `dubctl-phone-camera` with resolver tests.
2. Dubnium: introduce the general camera host capability and remove `video-meeting.nix`/`dubnium.videoMeeting`.
3. Update both repositories' documentation and historical-current-state references where they describe the retired ownership model.
4. Merge after exact-head CI in each repository.
5. Enable `dubnium.camera.virtual.enable = true` on the desired graphical host in a separate activation slice if it is not already included in the camera capability PR.
6. Perform physical qualification after applying the host generation.

Dotfiles must remain usable before the Dubnium camera migration because `dubctl-phone-camera` retains legacy v4l2loopback sysfs discovery.

## Physical Qualification

After the host capability is enabled and applied:

```bash
readlink -f /dev/dubnium-camera
v4l2-ctl --list-devices
dubctl phone camera cameras
dubctl phone camera back
```

Verify:

- `/dev/dubnium-camera` resolves to the configured `/dev/videoN`;
- the loopback label is `Dubnium Virtual Camera` unless overridden;
- the phone is selected over USB ADB only;
- the producer attaches successfully;
- Zoom and browser applications can select the virtual camera after the producer is attached;
- disabling the host capability removes the stable alias after rebuild/switch.

Physical validation is required before claiming the end-to-end camera path is qualified.

## Security and Lifecycle Invariants

- No host or user-session configuration silently activates a physical or virtual camera producer.
- No microphone capture is added to the phone-camera fallback.
- ADB over TCP/IP is not selected by this helper.
- The host capability does not create a network listener.
- Dotfiles owns normal-user application/session behavior; Dubnium owns privileged/kernel capability.
- `/dev/dubnium-camera` is a namespaced stable alias owned only by the Dubnium camera capability.
- Disabling the virtual camera must not leave a stale advertised stable alias.
- Application toggles are independent and do not implicitly change host kernel capabilities.
