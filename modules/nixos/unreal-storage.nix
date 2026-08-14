{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.dubnium.unreal.storage;

  storageInit = pkgs.writeShellApplication {
    name = "unreal-storage-init";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.e2fsprogs
      pkgs.util-linux
    ];
    text = ''
      if [[ $EUID -ne 0 ]]; then
        echo "unreal-storage-init must run as root (use sudo)." >&2
        exit 77
      fi

      if [[ $# -ne 1 || ! "$1" =~ ^[1-9][0-9]*[KMGT]$ ]]; then
        echo "usage: sudo unreal-storage-init SIZE" >&2
        echo "SIZE must be an integer followed by K, M, G, or T." >&2
        echo "example: sudo unreal-storage-init 500G" >&2
        exit 64
      fi

      size="$1"
      backing_mount=${lib.escapeShellArg cfg.backingMount}
      image=${lib.escapeShellArg cfg.imagePath}
      owner=${lib.escapeShellArg cfg.owner}
      group=${lib.escapeShellArg cfg.group}

      if ! mountpoint -q -- "$backing_mount"; then
        echo "Backing storage is not mounted: $backing_mount" >&2
        echo "Refusing to create the image on the root filesystem by accident." >&2
        exit 69
      fi

      case "$image" in
        "$backing_mount"/*) ;;
        *)
          echo "Image path is outside backing mount: $image" >&2
          exit 78
          ;;
      esac

      if [[ -e "$image" || -L "$image" ]]; then
        echo "Unreal storage image already exists: $image" >&2
        exit 73
      fi

      backing_fstype="$(findmnt -n -o FSTYPE --target "$backing_mount")"
      backing_options="$(findmnt -n -o OPTIONS --target "$backing_mount")"
      if [[ "$backing_fstype" == "ntfs3" && ",$backing_options," != *,sparse,* ]]; then
        echo "warning: $backing_mount uses ntfs3 without the sparse mount option" >&2
        echo "the image will still work, but physical allocation may grow less efficiently" >&2
      fi

      available_bytes="$(df --output=avail -B1 -- "$backing_mount" | tail -n 1 | tr -d ' ')"

      tmp_mount=""
      success=0
      image_created=0
      cleanup() {
        preserve_image=0
        if [[ -n "$tmp_mount" ]] && mountpoint -q -- "$tmp_mount"; then
          if ! umount -- "$tmp_mount"; then
            echo "warning: failed to unmount $tmp_mount; preserving $image" >&2
            preserve_image=1
          fi
        fi
        if [[ -n "$tmp_mount" ]] && ! mountpoint -q -- "$tmp_mount"; then
          rmdir -- "$tmp_mount" 2>/dev/null || true
        fi
        if [[ $success -ne 1 && $image_created -eq 1 && $preserve_image -eq 0 ]]; then
          rm -f -- "$image"
        fi
      }
      trap cleanup EXIT

      image_parent="$(dirname -- "$image")"
      install -d -m 0755 -- "$image_parent"

      resolved_backing="$(realpath -e -- "$backing_mount")"
      resolved_parent="$(realpath -e -- "$image_parent")"
      case "$resolved_parent" in
        "$resolved_backing"|"$resolved_backing"/*) ;;
        *)
          echo "Resolved image parent escapes backing mount: $resolved_parent" >&2
          exit 78
          ;;
      esac

      if ! (set -o noclobber; : > "$image") 2>/dev/null; then
        echo "Refusing to replace an image path created concurrently: $image" >&2
        exit 73
      fi
      image_created=1
      chmod 0600 -- "$image"
      truncate -s "$size" -- "$image"

      logical_bytes="$(stat -c %s -- "$image")"
      if (( logical_bytes > available_bytes )); then
        echo "Requested logical image size exceeds free space on $backing_mount." >&2
        echo "requested: $logical_bytes bytes; pre-creation available: $available_bytes bytes" >&2
        exit 75
      fi

      tmp_mount="$(mktemp -d /run/unreal-storage-init.XXXXXX)"
      mkfs.ext4 -F -L unreal-store "$image"
      mount -o loop,noatime "$image" "$tmp_mount"

      chown "$owner:$group" "$tmp_mount"
      chmod 0755 "$tmp_mount"
      install -d -m 0755 -o "$owner" -g "$group" \
        "$tmp_mount/Engine" \
        "$tmp_mount/Projects" \
        "$tmp_mount/Toolchains"

      sync -f "$tmp_mount"
      umount -- "$tmp_mount"
      success=1

      echo "Created Unreal ext4 storage image: $image ($size logical size)"
      echo "After the NixOS storage module is active, access it at: ${cfg.mountPoint}"
      du -h -- "$image"
    '';
  };
in
{
  options.dubnium.unreal.storage = {
    enable = lib.mkEnableOption "loop-mounted native Linux storage for Unreal Engine data";

    backingMount = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/isotope";
      description = "Existing mounted filesystem that stores the Unreal ext4 image";
    };

    imagePath = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/isotope/Unreal/unreal.ext4";
      description = "Path to the pre-created ext4 filesystem image used for Unreal storage";
    };

    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/srv/unreal";
      description = "Native Linux mount point exposed to Unreal Engine and its toolchains";
    };

    owner = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "User that owns the root and initial directories created in a new image";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group that owns the root and initial directories created in a new image";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/" cfg.backingMount && cfg.backingMount != "/";
        message = "dubnium.unreal.storage.backingMount must be an absolute non-root mount point";
      }
      {
        assertion =
          lib.hasPrefix "${cfg.backingMount}/" cfg.imagePath
          && cfg.imagePath != cfg.backingMount;
        message = "dubnium.unreal.storage.imagePath must be beneath backingMount";
      }
      {
        assertion =
          lib.hasPrefix "/" cfg.mountPoint
          && cfg.mountPoint != "/"
          && cfg.mountPoint != "/nix"
          && cfg.mountPoint != "/nix/store"
          && !lib.hasPrefix "/nix/store/" cfg.mountPoint
          && !lib.hasPrefix "${cfg.backingMount}/" cfg.mountPoint;
        message = "dubnium.unreal.storage.mountPoint must be a safe absolute path outside backingMount and /nix";
      }
    ];

    environment.systemPackages = [ storageInit ];

    fileSystems.${cfg.mountPoint} = {
      device = cfg.imagePath;
      fsType = "ext4";
      depends = [ cfg.backingMount ];
      options = [
        "loop"
        "noatime"
        "nofail"
        "x-systemd.automount"
        "x-systemd.idle-timeout=15min"
      ];
    };
  };
}
