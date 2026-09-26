{
  config,
  lib,
  pkgs,
  ...
}:
let
  machineProfile = config.dotfiles.host.name;
  machineProfileName = if machineProfile == null then "unconfigured" else machineProfile;
  taskPromotedProfilesRoot = ../../files/home/.config/task/custom.d;
  taskPromotedProfile = taskPromotedProfilesRoot + "/${machineProfileName}";
  taskPromotedIndex = taskPromotedProfile + "/index.rc";
  hasTaskPromotedIndex = machineProfile != null && builtins.pathExists taskPromotedIndex;
in
{
  home = {
    packages = [
      (pkgs.taskwarrior3 or pkgs.taskwarrior)
    ];

    file.".taskrc".source = ../../files/home/.taskrc;

    activation.ensureTaskRuntimeFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
  };

  xdg = {
    configFile = {
      # Managed config subdirectories - sourced by the generated .taskrc
      "task/sync".source = ../../files/home/.config/task/sync;
      "task/themes".source = ../../files/home/.config/task/themes;
      "task/uda".source = ../../files/home/.config/task/uda;
      "task/reports".source = ../../files/home/.config/task/reports;
      "task/holidays".source = ../../files/home/.config/task/holidays;

      # Stable include bridge for the reviewed machine-profile layer. The bridge is
      # always managed; it is an inert comment until a reviewed profile index exists.
      "task/custom.d/promoted.rc".text =
        if hasTaskPromotedIndex then
          ''
            include ~/.config/task/custom.d/${machineProfileName}/index.rc
          ''
        else
          ''
            # No reviewed Taskwarrior promoted profile for ${machineProfileName}.
          '';

      "task/custom.d/${machineProfileName}/index.rc" = lib.mkIf hasTaskPromotedIndex {
        source = taskPromotedIndex;
      };

      # Configctl layer directories
      "task/adopted.d/00-empty.rc".text = ''
        # Reserved for Nix-managed adopted profiles
      '';
    };
  };
}
