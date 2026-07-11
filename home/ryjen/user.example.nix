# Copy to user.local.nix and customize local, non-secret selections.
# Use a path flake so ignored files are included:
#   home-manager switch --flake "path:$PWD#ryjen@dubnium"
#
# This file is the canonical catalog of supported portable user selections.
# Keep only deliberate overrides active. Uncomment every portable option only
# when maintaining a complete user-level desired-state file.
{ ... }:
{
  # Personal identity. Replace both placeholders together in user.local.nix.
  # The Git module enforces user.useConfigOnly globally.
  programs.git = {
    userName = "Your Name";
    userEmail = "you@example.com";
  };

  # Portable overrides. Tracked profiles provide defaults through mkDefault.
  # dotfiles.agents.hermes.enable = false;
  # dotfiles.agents.antigravity.enable = false;

  # dotfiles.uv.enable = false;
  # dotfiles.uv.toolsFile = ".config/uv/tools.toml";

  # dotfiles.npm.enable = false;
  # dotfiles.npm.prefix = "${config.home.homeDirectory}/.local/share/npm";
  # dotfiles.npm.globalPackagesFile = ".config/npm/global-packages.txt";

  # dotfiles.pip.enable = false;
  # dotfiles.pip.prefix = "${config.home.homeDirectory}/.local/share/pip";
  # dotfiles.pip.globalPackagesFile = ".config/pip/global-packages.txt";

  # dotfiles.music.enable = false;
  # dotfiles.grimblast.enable = false;
  # dotfiles.graphical.keyring.enable = false;

  # dotfiles.headroom.proxy.enable = false;
  # dotfiles.headroom.proxy.host = "127.0.0.1";
  # dotfiles.headroom.proxy.port = 8787;
  # dotfiles.headroom.proxy.package = "${config.home.homeDirectory}/.local/libexec/headroom-proxy";

  # dotfiles.opsCadence.enable = false;
  # dotfiles.opsCadence.timers.enable = true;

  # Current grouped/profile selections. These remain listed until migrated to
  # stable tool, feature, desktop, service, or integration namespaces.
  # dotfiles.profiles.android.enable = false;
  # dotfiles.profiles.browser.enable = false;
  # dotfiles.profiles.micrantha.enable = false;
  # dotfiles.profiles.office.enable = false;

  # Optional runtime path containing a GPG fingerprint. Do not place the key
  # itself or other secret material in this file.
  # dotfiles.gpg.defaultKeyFile = null;

  # Host identity, role/capability options, adopted desktop profiles, and
  # machine-specific paths intentionally remain in tracked host profiles.
}
