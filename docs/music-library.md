# Managed music library

The managed music workflow separates metadata ownership from playback state:

```text
beets -> tagged files -> MPD -> rmpc / MPRIS -> Waybar
                     \
                      -> mpv remains available for ad-hoc media and video
```

## Ownership

- **beets** remains the canonical metadata and library-management authority.
- **MPD** owns only its derived tag cache, current queue, playback state, and stored playlists.
- **rmpc** is the interactive MPD library/queue/playlist client.
- **mpv** remains the general-purpose player for video, URLs, and files outside the managed collection.

Do not use an MPD client as a tag-writing authority. Metadata changes should continue to flow through beets and the tagged files.

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
- MPD filesystem auto-update so beets-driven file/tag changes are picked up without requiring a second metadata authority;
- `mpd-mpris` for `playerctl` and Waybar integration;
- `rmpc` as the terminal library browser/controller;
- a **Music Library** desktop entry, available through the normal application launcher;
- `$XDG_DATA_HOME/mpd/playlists` as the shared persisted playlist directory.

## Playback controls

`music-playerctl` provides deterministic MPRIS selection for the music widget and scripts:

1. `MUSIC_PLAYER` when explicitly set and available;
2. playing MPD;
3. playing mpv;
4. paused MPD;
5. paused mpv;
6. stopped/available MPD;
7. stopped/available mpv.

This lets managed-library playback prefer MPD without preventing an actively playing ad-hoc mpv instance from being controlled when MPD is idle.

Useful diagnostics:

```sh
systemctl --user status mpd mpd-mpris
journalctl --user -u mpd -u mpd-mpris
playerctl --player=mpd status
rmpc
```

## Beets integration

The repository intentionally does **not** take ownership of `~/.config/beets/config.yaml`; that file may contain personal import, path, metadata-source, and plugin settings that should not be replaced by Home Manager.

Instead, Home Manager writes `~/.config/beets/dotfiles-mpd.yaml` with the MPD, playlist, and smart-playlist settings. To enable the deeper beets integration, merge the following into the existing beets configuration while preserving any existing plugins:

```yaml
include: dotfiles-mpd.yaml
plugins: <existing plugins> mpdupdate playlist smartplaylist
```

If `include` or `plugins` already exists, extend the existing value rather than replacing it.

The generated smart-playlist configuration includes `recently-added.m3u` for tracks added in the last four weeks. Regenerate smart playlists with:

```sh
beet splupdate
```

MPD/rmpc read generated and user-curated M3U playlists from the same playlist directory.

The core MPD library does not depend on this optional plugin step: MPD's filesystem auto-update keeps its derived index current as beets changes tags or paths.

## Safety boundary

The existing `music-dislike` delete/trash workflow remains mpv-specific for now. Applying it blindly to MPD would mutate the filesystem without updating the canonical beets library database. Any managed-library deletion workflow should be implemented through beets first, then projected to MPD.
