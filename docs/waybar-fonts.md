# Waybar Nerd Font troubleshooting

Waybar icon rendering depends on two separate pieces being correct:

1. Nerd Font packages must be installed into the system font set.
2. Waybar CSS must name font families that fontconfig can actually resolve.

This repo installs both JetBrains Mono Nerd Font and Symbols Nerd Font. Waybar should therefore prefer:

```css
font-family: "JetBrainsMono Nerd Font Mono", "JetBrainsMono Nerd Font", "Symbols Nerd Font Mono", "Roboto", "sans-serif";
```

## Local verification

After rebuilding, verify the font names that Waybar is expected to use:

```sh
fc-match "JetBrainsMono Nerd Font Mono"
fc-match "JetBrainsMono Nerd Font"
fc-match "Symbols Nerd Font Mono"
fc-list | grep -Ei 'JetBrainsMono|Symbols Nerd'
```

Then restart the user session or restart Waybar after rebuilding:

```sh
pkill waybar
waybar &
```

If icons still render as boxes after those checks, the problem is probably stale session state or a local CSS override in `~/.config/waybar/custom.css`, not missing system font packages.
