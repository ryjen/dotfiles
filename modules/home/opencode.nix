{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.opencode;
  machineProfile = config.dotfiles.host.name;
  machineProfileName = if machineProfile == null then "unconfigured" else machineProfile;
  managedConfigProfile = if cfg.configProfile == null then machineProfileName else cfg.configProfile;
  managedConfig = ../../files/home/.config/opencode/config.d/${managedConfigProfile}/config.json;
  npmBin = "${config.dotfiles.npm.prefix}/bin";

  # OpenCode's Wayland clipboard backend launches wl-copy in the same terminal
  # process group. wl-copy backgrounds itself without creating a new session, so
  # suspending OpenCode with Ctrl-Z can also suspend the clipboard provider and
  # make a subsequent paste block. Keep the workaround scoped to OpenCode.
  # Upstream: https://github.com/anomalyco/opencode/issues/42162
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
  options.dotfiles.opencode = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable OpenCode terminal integration";
    };

    configProfile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "dubnium";
      description = ''
        Reviewed configctl profile to project as OpenCode config.json. When null,
        the current dotfiles host name is used.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.dotfiles.npm.enable;
        message = "dotfiles.opencode requires dotfiles.npm because OpenCode is installed through the mutable npm tool prefix";
      }
      {
        assertion = builtins.pathExists managedConfig;
        message = "dotfiles.opencode config profile '${managedConfigProfile}' has no reviewed config.d/${managedConfigProfile}/config.json";
      }
    ];

    # home.sessionPath is prepended to PATH. mkBefore keeps this wrapper ahead
    # of the mutable npm bin directory while the wrapper itself executes the
    # npm-managed OpenCode binary by absolute path.
    home.sessionPath = lib.mkBefore [ "${opencodeWrapper}/bin" ];

    # configctl owns reviewed OpenCode fragments under config.d/<profile>.
    # Normally the host name selects that fragment. Compatibility profiles may
    # explicitly reuse another reviewed config through configProfile instead of
    # relying on an implicit fallback or duplicating config files.
    # config.local.json is a machine-local escape hatch Home Manager never
    # overwrites.
    xdg.configFile."opencode/config.json" = {
      source = managedConfig;
    };
  };
}
