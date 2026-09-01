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
  options.dotfiles.opencode.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable OpenCode terminal integration";
  };

  config = lib.mkIf cfg.enable {
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

    # configctl owns the per-host OpenCode config. The reviewed fragment lives
    # beneath the machine-profile namespace (config.d/<host>/config.json); Home
    # Manager projects the active host's fragment to config.json. Using the
    # machine-profile name as a path component (not a branching conditional)
    # keeps host selection in configctl, per schema-v1.
    #   - dubnium (and other non-technetium hosts): local Headroom proxy at
    #     127.0.0.1:8787; upstream set per host in home/ryjen/profiles/dubnium.nix.
    #   - technetium: published Headroom proxy on the tailnet
    #     (headroom.tail4d84c.ts.net); no local proxy in front of OpenCode.
    # config.local.json is a machine-local escape hatch Home Manager never
    # overwrites.
    xdg.configFile."opencode/config.json" = lib.mkIf cfg.enable {
      source = ../../files/home/.config/opencode/config.d/${machineProfileName}/config.json;
    };
  };
}
