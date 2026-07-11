# Copy to user.local.nix and customize local, non-secret selections.
# Use a path flake so ignored files are included:
#   home-manager switch --flake "path:$PWD#ryjen@dubnium"
#
# This file is the canonical catalog of supported local selections. Keep every
# user-facing toggle here when options are added, renamed, or removed.
{ config, ... }:
{
  # Personal identity. Replace placeholders in user.local.nix only.
  programs.git = {
    userName = "Your Name";
    userEmail = "you@example.com";
    settings.user.useConfigOnly = true;
  };

  # Independently selectable agents.
  dotfiles.agents = {
    hermes.enable = false;
    antigravity.enable = false;
  };

  # Tool environments.
  dotfiles.uv = {
    enable = false;
    toolsFile = ".config/uv/tools.toml";
  };

  dotfiles.npm = {
    enable = false;
    prefix = "${config.home.homeDirectory}/.local/share/npm";
    globalPackagesFile = ".config/npm/global-packages.txt";
  };

  dotfiles.pip = {
    enable = false;
    prefix = "${config.home.homeDirectory}/.local/share/pip";
    globalPackagesFile = ".config/pip/global-packages.txt";
  };

  # User-facing capabilities.
  dotfiles.music = {
    enable = false;
    musicDirectory = "${config.home.homeDirectory}/Music";
  };

  dotfiles.grimblast.enable = false;
  dotfiles.graphical.keyring.enable = false;

  dotfiles.headroom.proxy = {
    enable = false;
    host = "127.0.0.1";
    port = 8787;
    package = "${config.home.homeDirectory}/.local/libexec/headroom-proxy";
  };

  dotfiles.opsCadence = {
    enable = false;
    timers.enable = true;
  };

  # Current grouped/profile selections. These remain listed until migrated to
  # stable tool, feature, desktop, service, or integration namespaces.
  dotfiles.profiles = {
    android.enable = false;
    browser.enable = false;
    micrantha.enable = false;
    office.enable = false;
    workstation.enable = false;
  };

  # Non-secret local profile choices.
  dotfiles.alacritty.adoptedProfile = "empty"; # empty | dubnium
  dotfiles.hypr.adoptedProfile = "empty"; # empty | dubnium | technetium

  # Optional runtime path containing a GPG fingerprint. Do not place the key
  # itself or other secret material in this file.
  dotfiles.gpg.defaultKeyFile = null;

  # Host capability options are intentionally absent. They remain in tracked
  # profiles because they describe machine support rather than user choice.
}