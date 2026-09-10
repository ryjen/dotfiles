{ lib, ... }:
{
  imports = [
    ./workstation.nix
  ];

  dotfiles = {
    host.name = "dubnium";
    profiles = {
      browser.enable = lib.mkDefault true;
      android.enable = lib.mkDefault false;
      micrantha.enable = lib.mkDefault false;
      office.enable = lib.mkDefault true;
    };
    openwork = {
      enable = lib.mkDefault true;
      sandbox.allowSshAgent = lib.mkDefault true;
    };
    tidyfs.enable = lib.mkDefault true;
    hypr.adoptedProfile = "dubnium";

    # When Unreal is explicitly enabled, use the native Linux filesystem mounted
    # from the optional isotope-backed storage image. This path selection alone
    # does not enable Unreal or the storage module.
    unreal.engineRoot = lib.mkDefault "/srv/unreal/Engine/5.8";

    bitwarden = {
      cli.enable = lib.mkDefault true;
      desktop.enable = lib.mkDefault false;
    };

    # Canonical music directory for shells and graphical-session processes.
    music = {
      enable = lib.mkDefault true;
      musicDirectory = lib.mkDefault "/mnt/isotope/Music";
      mpd.enable = lib.mkDefault true;
    };

    # Headroom proxy forwards to the Dubnium supervisor gateway published via
    # Tailscale Serve. OpenCode (and other AI clients) reach Headroom at the
    # local proxy on 127.0.0.1:8787; this is the upstream it forwards to.
    headroom.proxy.upstreamUrl = "https://supervisor.tail4d84c.ts.net/v1";
  };
}
