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

  # Schema for a single OpenCode MCP server entry. This lives in the let binding
  # as a module value so the option surface only declares the portable
  # dotfiles.opencode.mcp path, not the per-server sub-fields.
  mcpServerSubmodule = {
    options = {
      type = lib.mkOption {
        type = lib.types.str;
        default = "local";
        description = "OpenCode MCP transport type; local stdio servers use \"local\".";
      };

      command = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Command and arguments OpenCode runs for the MCP server.";
      };

      enabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether OpenCode should start this MCP server.";
      };
    };
  };
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

    mcp = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule mcpServerSubmodule);
      default = { };
      example = lib.literalExpression ''
        {
          serena = {
            command = [
              "''${config.home.homeDirectory}/.local/bin/serena"
              "start-mcp-server"
              "--project-from-cwd"
              "--context"
              "agent"
            ];
          };
        }
      '';
      description = ''
        MCP servers rendered into the Home Manager-owned OpenCode config.json.

        Register servers here rather than in the hand-written
        ~/.config/opencode/opencode.json, which OpenCode loads afterwards and
        would otherwise override the managed value.
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
    # The reviewed fragment is the base config. Declarative MCP servers are
    # rendered on top so they are owned by Home Manager instead of drifting into
    # the hand-written opencode.json override file. When no MCP servers are
    # configured the reviewed fragment is projected unchanged.
    xdg.configFile."opencode/config.json".source =
      if cfg.mcp == { } then
        managedConfig
      else
        pkgs.writeText "opencode-config.json" (
          builtins.toJSON (
            builtins.fromJSON (builtins.readFile managedConfig)
            // {
              mcp = lib.mapAttrs (_: server: {
                inherit (server) type command enabled;
              }) cfg.mcp;
            }
          )
        );
  };
}
