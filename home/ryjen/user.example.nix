# Copy to user.local.nix and customize local, non-secret selections.
# Use a path flake so ignored files are included:
#   home-manager switch --flake "path:$PWD#ryjen@dubnium"
#
# This file is the canonical catalog of supported portable user selections.
# Keep only deliberate overrides active. Uncomment every portable option only
# when maintaining a complete user-level desired-state file.
# deadnix ignore
{ config, ... }:
{
  # Personal identity. Replace both placeholders together in user.local.nix.
  # The Git module enforces user.useConfigOnly globally.
  programs.git = {
    userName = "Your Name";
    userEmail = "you@example.com";
  };

  # Portable overrides. Tracked profiles provide defaults through mkDefault.
  # Package implementation overrides intentionally remain tracked in modules.
  # dotfiles.agents.hermes.enable = false;
  # dotfiles.agents.antigravity.enable = false;

  # dotfiles.uv.enable = false;
  # dotfiles.uv.toolsFile = ".config/uv/tools.toml";

  # dotfiles.npm.enable = false;
  # dotfiles.npm.prefix = "${config.home.homeDirectory}/.local/share/npm";
  # dotfiles.npm.globalPackagesFile = ".config/npm/global-packages.txt";

  # OpenCode is installed through the mutable npm tool prefix. Its wrapper keeps
  # the Wayland clipboard provider outside OpenCode's terminal job-control group.
  # dotfiles.opencode.enable = false;

  # Playwright is Nix-managed so browser binaries remain immutable and version-
  # aligned with the packaged CLI instead of being downloaded into a user cache.
  # dotfiles.playwright.enable = false;

  # dotfiles.pip.enable = false;
  # dotfiles.pip.prefix = "${config.home.homeDirectory}/.local/share/pip";
  # dotfiles.pip.globalPackagesFile = ".config/pip/global-packages.txt";

  # Rootless Podman remains available without exposing its control socket.
  # Unsigned compatibility exceptions must be fully qualified and narrowly scoped.
  # dotfiles.podman.apiSocket.enable = false;
  # dotfiles.podman.allowedUnsignedRegistries = [
  #   "docker.io"
  #   "ghcr.io"
  # ];

  # The OpenSSH agent defaults on when Home Manager user systemd is available.
  # Disable it when another trusted provider deliberately owns SSH_AUTH_SOCK.
  # dotfiles.sshAgent.enable = false;

  # Bitwarden clients. The Dubnium workstation profile enables both by default;
  # use these explicit selections when maintaining a complete local config.
  # dotfiles.bitwarden.cli.enable = true;
  # dotfiles.bitwarden.desktop.enable = true;
  # dotfiles.bitwarden.serverUrl = null;
  # Set either client value to false to disable it independently. Set serverUrl
  # to an explicit http(s) origin when using a self-hosted Bitwarden/Vaultwarden.

  # dotfiles.ebooks.enable = false;
  # dotfiles.music.enable = false;
  # dotfiles.music.musicDirectory = "${config.home.homeDirectory}/Music";
  # dotfiles.music.mpd.enable = false;
  # dotfiles.grimblast.enable = false;
  # dotfiles.graphical.keyring.enable = false;
  # dotfiles.idle.enable = false;

  # Hardware/profile variants that are safe to select locally.
  # dotfiles.kitty.adoptedProfile = "empty";
  # dotfiles.hypr.adoptedProfile = "empty";
  # dotfiles.waybar.variant = "workstation";

  # Unreal Editor support remains disabled unless explicitly selected. Keep the
  # Epic installed build outside the Nix store and Zen/DDC in writable cache data.
  # dotfiles.unreal.enable = false;
  # dotfiles.unreal.engineRoot = "${config.xdg.dataHome}/unreal-engine";
  # dotfiles.unreal.cacheRoot = "${config.xdg.cacheHome}/unreal-engine";

  # OpenWork desktop app and sandbox boundary.
  # dotfiles.openwork.enable = false;
  # dotfiles.openwork.sandbox.enable = true;
  # dotfiles.openwork.sandbox.workspacePaths = [ "${config.home.homeDirectory}/Projects" ];
  # dotfiles.openwork.sandbox.allowNetwork = true;
  # dotfiles.openwork.sandbox.allowSshAgent = false;

  # Meeting workspace support. Output names and camera identifiers are
  # machine-local; inspect them before replacing these null placeholders.
  # dotfiles.meeting.enable = false;
  # dotfiles.meeting.presentationOutput = null; # For example, "DP-1".
  # dotfiles.meeting.cameraDevice = null; # For example, "/dev/v4l/by-id/...".
  # dotfiles.meeting.teamsClassRegex = "^(firefox|Microsoft-edge|microsoft-edge)$";
  # dotfiles.meeting.teamsTitleRegex = "^Microsoft Teams.*$";

  # dotfiles.headroom.proxy.enable = false;
  # dotfiles.headroom.proxy.host = "127.0.0.1";
  # dotfiles.headroom.proxy.port = 8787;
  # dotfiles.headroom.proxy.package = "${config.home.homeDirectory}/.local/libexec/headroom-proxy";
  # dotfiles.headroom.proxy.upstreamUrl = "http://127.0.0.1:8000/v1";
  # dotfiles.headroom.mcp.enable = false;
  # dotfiles.headroom.mcp.package = "${config.home.homeDirectory}/.local/libexec/headroom-mcp";

  # Current grouped/profile selections. These remain listed until migrated to
  # stable tool, feature, desktop, service, or integration namespaces.
  # dotfiles.profiles.android.enable = false;
  # dotfiles.profiles.browser.enable = false;
  # dotfiles.profiles.micrantha.enable = false;
  # dotfiles.profiles.office.enable = false;
  # dotfiles.profiles.workstation.enable = false;

  # Optional runtime path containing a GPG fingerprint. Do not place the key
  # itself or other secret material in this file.
  # dotfiles.gpg.defaultKeyFile = null;

  # Host identity, role/capability options, adopted desktop profiles, and
  # machine-specific paths intentionally remain in tracked host profiles.
}
