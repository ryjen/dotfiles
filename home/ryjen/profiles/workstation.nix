{ config, lib, ... }:
{
  imports = [
    ./graphical.nix
  ];

  dotfiles = {
    host.role = "workstation";
    profiles.workstation.enable = true;
    ebooks.enable = lib.mkDefault true;
    opencode.enable = lib.mkDefault true;

    # Serena MCP registration is declarative so it survives rebuilds and does
    # not drift into the hand-written opencode.json. The serena binary comes
    # from a manual pinned uv tool install today; making that install
    # declarative is tracked as a separate configctl uv-tools follow-up.
    opencode.mcp.serena = {
      type = "local";
      command = [
        "${config.home.homeDirectory}/.local/bin/serena"
        "start-mcp-server"
        "--project-from-cwd"
        "--context"
        "agent"
        "--open-web-dashboard"
        "False"
      ];
    };
    meeting = {
      enable = lib.mkDefault true;
      zoom.enable = lib.mkDefault true;
      teams.enable = lib.mkDefault true;
      phoneCamera.enable = lib.mkDefault true;
    };
    agents = {
      hermes.enable = lib.mkDefault true;
      antigravity.enable = lib.mkDefault true;
    };
    headroom.proxy.enable = lib.mkDefault true;

    # Register the Headroom MCP server with OpenCode declaratively. This installs
    # the launcher and lets headroom.nix contribute the managed MCP entry instead
    # of the hand-written opencode.json.
    headroom.mcp.enable = lib.mkDefault true;
    playwright.enable = lib.mkDefault true;
  };
}
