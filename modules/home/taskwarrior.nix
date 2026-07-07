{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.taskwarrior3 or pkgs.taskwarrior)
  ];

  home.file.".taskrc".source = ../../files/home/.taskrc;

  # Managed config subdirectories - sourced by the generated .taskrc
  xdg.configFile."task/sync".source = ../../files/home/.config/task/sync;
  xdg.configFile."task/themes".source = ../../files/home/.config/task/themes;
  xdg.configFile."task/uda".source = ../../files/home/.config/task/uda;
  xdg.configFile."task/reports".source = ../../files/home/.config/task/reports;
  xdg.configFile."task/holidays".source = ../../files/home/.config/task/holidays;

  # Configctl layer directories
  xdg.configFile."task/adopted.d/00-empty.rc".text = ''
    # Reserved for Nix-managed adopted profiles
  '';

  home.activation.ensureTaskRuntimeFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    task_config_dir="${config.xdg.configHome}/task"
    mkdir -p "$task_config_dir/custom.d"

    if [ ! -e "$task_config_dir/local.rc" ]; then
      cat > "$task_config_dir/local.rc" <<'EOF'
# Local Taskwarrior overrides.
EOF
    fi

    if [ ! -e "$task_config_dir/custom.d/index.rc" ]; then
      cat > "$task_config_dir/custom.d/index.rc" <<'EOF'
# User-managed Taskwarrior custom includes.
EOF
    fi
  '';
}
