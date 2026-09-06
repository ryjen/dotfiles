# Managed music library

The managed music workflow separates metadata ownership from playback state:

```text
beets -> tagged files -> MPD -> rmpc
                         \-> MPRIS -> Waybar

mpv remains available for ad-hoc media and video only.
```

## Ownership

- **beets** is the canonical metadata and library-management authority.
- **MPD** owns its derived tag cache, current queue, playback state, and stored playlists.
- **rmpc** is the single interactive managed-music UI for browsing, queueing, searching, and playlists.
- **Waybar** exposes lightweight MPD playback controls only.
- **mpv** remains the general-purpose player for video, URLs, and files outside the managed collection.

Do not use MPD/rmpc as a tag-writing authority. Metadata changes continue to flow through beets and the tagged files.

## Declarative configuration

Enable the base music tooling and the MPD backend:

```nix
dotfiles.music = {
  enable = true;
  musicDirectory = "/path/to/Music";
  mpd.enable = true;
};
```

The Dubnium profile enables this against `/mnt/isotope/Music`.

The module configures:

- MPD as a Home Manager user service;
- loopback-only MPD control on `127.0.0.1:6600`;
- zeroconf disabled by default;
- PipeWire output and ReplayGain auto mode;
- MPD filesystem auto-update;
- `mpd-mpris` for Waybar/MPRIS integration;
- `rmpc` as the terminal library/queue/playlist UI;
- a single **Music Library** desktop entry for the normal application launcher;
- `$XDG_DATA_HOME/mpd/playlists` as the persisted playlist directory.

There is intentionally no separate `Music Window` or mpv-backed managed-music launcher.

## Music Library / rmpc

Open **Music Library** from the normal launcher. rmpc retains its defaults and adds a small stable workflow:

| Key | Action |
| --- | --- |
| `1` | Queue |
| `2` | Directories |
| `3` | Playlists |
| `4` | Artists |
| `5` | Albums |
| `6` | Search |
| `P` | Replace the queue with the highlighted item/collection/playlist and play it |
| `w` | Add highlighted item(s) to a new or existing playlist |
| `W` | Add all items in the current pane to a new or existing playlist |
| `?` | Show rmpc's full help/keymap |

To create a playlist, browse or search for music, highlight one or more items, press `w`, and choose a new playlist name in the modal. Press `3` to browse persisted playlists and `P` to play the highlighted playlist immediately.

MPD owns playlist persistence; rmpc is only the interactive client. Generated beets smart playlists and manually curated rmpc playlists share the same MPD playlist directory.

## Waybar controls

The Dubnium music widget controls MPD directly:

- left click: play/pause; if the MPD queue is empty, seed it from the managed library and start playback;
- right click: next track;
- middle click: previous track;
- scroll up/down: seek forward/back ten seconds.

The implementation helpers live under `~/.local/libexec` and are deliberately not user-facing CLI commands. The Technetium profile does not enable managed MPD and therefore does not expose the managed-music Waybar widget.

Useful diagnostics:

```sh
systemctl --user status mpd mpd-mpris
journalctl --user -u mpd -u mpd-mpris
playerctl --player=mpd status
mpc status
rmpc
```

## Configctl ownership

The workflow is represented explicitly in the dotfiles configctl app-contract surface:

- **MPD** is active as a `native-include` contract. Home Manager owns the generated root config; MPD loads configctl-controlled `custom.d/*.conf` and `local.conf` through `include_optional`.
- **rmpc** is a planned `compose` contract. Its stable RON source lives at `files/home/.config/rmpc/base.ron`; Home Manager remains the runtime writer until reviewed structured composition ownership is activated.
- **beets** is a planned `compose` contract. The existing `config.yaml` remains user-owned until takeover can preserve personal import/plugin settings safely.

The normal MPD configctl workflow is:

```sh
configctl status mpd
configctl adopt mpd
# edit ~/.config/mpd/custom.d/<name>.conf or ~/.config/mpd/local.conf
configctl status mpd
configctl promote mpd <name>.conf
```

`local.conf` remains machine-local and unpromoted.

## Beets integration

Home Manager writes `~/.config/beets/dotfiles-mpd.yaml` with MPD, playlist, and smart-playlist settings. To opt the existing beets configuration into the deeper integration while preserving current settings:

```yaml
include: dotfiles-mpd.yaml
plugins: <existing plugins> mpdupdate playlist smartplaylist
```

If `include` or `plugins` already exists, extend rather than replace it.

The generated smart-playlist configuration includes `recently-added.m3u` for tracks added in the last four weeks. Regenerate smart playlists with:

```sh
beet splupdate
```

The core MPD library does not depend on the optional plugin step: MPD filesystem auto-update keeps its derived index current as beets changes tags or paths.

## Safety boundary

Managed-library deletion must go through beets first and then be projected to MPD. The old mpv-specific `music-dislike`/trash path has been removed because directly deleting files would bypass the canonical beets database.
