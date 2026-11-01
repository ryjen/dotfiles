# Waybar disk widget

The custom disk widget intentionally replaces Waybar's built-in `disk` module. Only `custom/disk` should be declared in the active Waybar configuration.

The widget reports root filesystem pressure in the bar and lists distinct persistent mounted devices in its tooltip. Boot mounts are intentionally omitted. NTFS mounts provided by `ntfs-3g` are commonly reported by Linux as `fuseblk`, so `fuseblk` must remain in the supported filesystem allowlist.

When `/` is Btrfs and the `btrfs` tools are available, the tooltip also shows bounded, read-only root details: backing source, device count, device size, allocated and unallocated space, estimated free space, missing space, data and metadata ratios, and quota/qgroup status. Every Btrfs command has a two-second timeout, requires no privilege escalation, and degrades to an unavailable status rather than blocking Waybar.

## I/O busy time versus storage capacity

The compact label prioritizes **root device I/O busy time** (`󰓅`) ahead
of root filesystem space consumed (`󰋊`). Both remain percentages, but they
have different meanings. A device can be 100% busy without being out of
space, and 100% busy on NVMe alone does not prove poor application latency.

The tooltip retains per-mounted-device read/write rates and now reports
root-device I/O pressure-stall information (PSI) `some` and `full` 10-second
averages from `/proc/pressure/io`. PSI is a host-wide stall indicator, **not**
the percentage of runner I/O; the widget deliberately does not infer
per-runner attribution or bypass Dubnium's RunnerStatus contract. Unavailable
PSI is displayed as `unavailable`, not as zero.

The existing warning/critical color thresholds apply to either low free
capacity or high instantaneous device busy time. Use the paired PSI numbers,
latency and device throughput before treating a short busy spike as an
incident. The `WAYBAR_DISK_IO_WARNING_PERCENT`,
`WAYBAR_DISK_IO_CRITICAL_PERCENT`, and
`WAYBAR_DISK_IO_SAMPLE_SECONDS` environment settings still control the
read-only sampling behavior.
