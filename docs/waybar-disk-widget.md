# Waybar disk widget

The custom disk widget intentionally replaces Waybar's built-in `disk` module. Only `custom/disk` should be declared in the active Waybar configuration.

The widget reports root filesystem pressure in the bar and lists distinct persistent mounted devices in its tooltip. Boot mounts are intentionally omitted. NTFS mounts provided by `ntfs-3g` are commonly reported by Linux as `fuseblk`, so `fuseblk` must remain in the supported filesystem allowlist.

When `/` is Btrfs and the `btrfs` tools are available, the tooltip also shows bounded, read-only root details: backing source, device count, device size, allocated and unallocated space, estimated free space, missing space, data and metadata ratios, and quota/qgroup status. Every Btrfs command has a two-second timeout, requires no privilege escalation, and degrades to an unavailable status rather than blocking Waybar.
