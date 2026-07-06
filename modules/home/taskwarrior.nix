{
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.taskwarrior3 or pkgs.taskwarrior)
  ];

  home.file.".taskrc".source = ../../files/home/.taskrc;

  # Managed config subdirectories — sourced by the generated .taskrc
  xdg.configFile."task/sync".source = ../../files/home/.config/task/sync;
  xdg.configFile."task/themes".source = ../../files/home/.config/task/themes;
  xdg.configFile."task/uda".source = ../../files/home/.config/task/uda;
  xdg.configFile."task/reports".source = ../../files/home/.config/task/reports;
  xdg.configFile."task/holidays".source = ../../files/home/.config/task/holidays;

  # Configctl layer directories
  xdg.configFile."task/adopted.d/00-empty.rc".text = ''
    # Reserved for Nix-managed adopted profiles
  '';

  xdg.configFile."task/custom.d/00-empty.rc".text = ''
    # Reserved for configctl custom fragments
  '';

  xdg.configFile."task/local.rc".text = ''
    # Place host-local or user overrides here.
  '';
}
