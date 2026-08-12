{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.opencode;
  npmBin = "${config.dotfiles.npm.prefix}/bin";

  # OpenCode's Wayland clipboard backend launches wl-copy in the same terminal
  # process group. wl-copy backgrounds itself without creating a new session, so
  # suspending OpenCode with Ctrl-Z can also suspend the clipboard provider and
  # make a subsequent paste block. Keep the workaround scoped to OpenCode.
  wlCopyShim = pkgs.writeShellScriptBin "wl-copy" ''
    exec ${pkgs.util-linux}/bin/setsid ${pkgs.wl-clipboard}/bin/wl-copy "$@"
  '';

  opencodeWrapper = pkgs.writeShellScriptBin "opencode" ''
    if [ ! -x "${npmBin}/opencode" ]; then
      echo "opencode is not installed in the configured npm prefix: ${npmBin}" >&2
      exit 127
    fi

    export PATH="${wlCopyShim}/bin:$PATH"
    exec "${npmBin}/opencode" "$@"
  '';
in
{
  options.dotfiles.opencode.enable = lib.mkEnableOption "OpenCode terminal integration";

  config = lib.mkMerge [
    {
      dotfiles.opencode.enable = lib.mkDefault (config.dotfiles.profiles.workstation.enable or false);
    }

    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = config.dotfiles.npm.enable;
          message = "dotfiles.opencode requires dotfiles.npm because OpenCode is installed through the mutable npm tool prefix";
        }
      ];

      # home.sessionPath is prepended to PATH. mkBefore keeps this wrapper ahead
      # of the mutable npm bin directory while the wrapper itself executes the
      # npm-managed OpenCode binary by absolute path.
      home.sessionPath = lib.mkBefore [ "${opencodeWrapper}/bin" ];
    })
  ];
}
