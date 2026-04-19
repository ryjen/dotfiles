{
  pkgs,
  ...
}:
{
  home.sessionVariables = {
    GIT_EDITOR = "nvim";
    PAGER = "bat -p";
    GOPATH = "$HOME/.local/share/go";
    PNPM_HOME = "$HOME/.local/share/pnpm";
    BUN_INSTALL = "$HOME/.bun";
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_DBUS_REMOTE = "1";
    GTK_CSD = "0";
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    TERMINAL_COMMAND = "${pkgs.alacritty}/bin/alacritty";
    ZEIT_DB = "$HOME/.config/zeit.db";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    OPENCV_LOG_LEVEL = "ERROR";
  };

  # JetBrains Toolbox installs CLI wrappers here when using the Toolbox app (non-Nix).
  home.sessionPath = [
    "$HOME/.local/share/go/bin"
    "$HOME/.local/share/pnpm"
    "$HOME/.bun/bin"
    "$HOME/.local/bin"
    "/usr/local/bin"
    "$HOME/.local/share/JetBrains/Toolbox/scripts"
    "$HOME/.asdf/shims"
  ];
}
