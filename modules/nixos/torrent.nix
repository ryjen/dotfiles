{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.dubnium.torrent;
in
{
  options.dubnium.torrent = {
    enable = lib.mkEnableOption "hardened Transmission BitTorrent service";

    downloadDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${username}/Downloads/Torrents";
      description = "Directory used for completed and in-progress torrent downloads.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.transmission = {
      enable = true;

      # system.stateVersion is intentionally older than the current package
      # default boundary, so select Transmission 4 explicitly.
      package = pkgs.transmission_4;

      # Keep downloads accessible to the interactive user through the
      # transmission group while retaining a dedicated daemon identity.
      downloadDirPermissions = "0770";
      openPeerPorts = false;
      openRPCPort = false;

      settings = {
        "download-dir" = cfg.downloadDir;
        "incomplete-dir" = "${cfg.downloadDir}/.incomplete";
        "incomplete-dir-enabled" = true;

        # BitTorrent protocol encryption reduces passive protocol inspection;
        # it is not an anonymity mechanism and does not hide the peer IP.
        encryption = "preferred";

        # Do not ask the LAN gateway to create inbound mappings implicitly.
        "port-forwarding-enabled" = false;
        "lpd-enabled" = false;

        # The CLI controls the daemon locally. Do not expose RPC to the LAN.
        "rpc-bind-address" = "127.0.0.1";
        "rpc-whitelist" = "127.0.0.1";
        "rpc-whitelist-enabled" = true;
        "rpc-host-whitelist-enabled" = true;
        "rpc-authentication-required" = false;

        # Group members may manage downloaded files; other users get no access.
        umask = "007";
      };
    };

    users.users.${username}.extraGroups = [ "transmission" ];
  };
}
