{ lib, ... }:
{
  imports = [
    ./laptop.nix
  ];

  dotfiles.host.name = "technetium";
  dotfiles.profiles.browser.enable = lib.mkDefault true;
  dotfiles.profiles.android.enable = lib.mkDefault false;
  dotfiles.profiles.micrantha.enable = lib.mkDefault false;
  dotfiles.hypr.adoptedProfile = "technetium";
  dotfiles.waybar.variant = "laptop";

  # Technetium is a client of the dubnium node. It runs no local inference and
  # no local vault server, so user-level AI and secret tooling points at the
  # services dubnium publishes through Tailscale Serve as named services.
  #
  # Headroom runs locally as the context-compression proxy for AI clients but
  # forwards upstream to dubnium's supervisor gateway (svc:supervisor) instead
  # of a loopback runtime that does not exist on this host.
  dotfiles.headroom.proxy = {
    enable = lib.mkDefault true;
    upstreamUrl = lib.mkDefault "https://supervisor.tail4d84c.ts.net/v1";
  };

  # Expose Headroom's compression tools to AI clients over MCP as well as the
  # proxy path. This is a stdio server started by each client on demand, so it
  # only installs the launcher; clients register it themselves.
  dotfiles.headroom.mcp.enable = lib.mkDefault true;

  # Vaultwarden clients target the self-hosted origin (svc:warden). The browser
  # extension cannot be configured declaratively and still needs its server URL
  # set by hand; see docs/bitwarden.md.
  dotfiles.bitwarden = {
    cli.enable = lib.mkDefault true;
    desktop.enable = lib.mkDefault true;
    serverUrl = lib.mkDefault "https://warden.tail4d84c.ts.net";
  };
}
