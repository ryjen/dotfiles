# Waybar disk widget

The custom disk widget intentionally replaces Waybar's built-in `disk` module. Only `custom/disk` should be declared in the active Waybar configuration.

The widget reports root filesystem pressure in the bar and lists distinct persistent mounted devices in its tooltip. NTFS mounts provided by `ntfs-3g` are commonly reported by Linux as `fuseblk`, so `fuseblk` must remain in the supported filesystem allowlist.

A follow-up enhancement should add bounded, read-only Btrfs details such as filesystem allocation, device count, estimated free space, and quota/qgroup status. The implementation must fail closed when Btrfs tooling is unavailable or access is denied, and must avoid blocking Waybar refreshes.
