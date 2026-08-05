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

  # dotfiles.pip.enable = false;
  # dotfiles.pip.prefix = "${config.home.homeDirectory}/.local/share/pip";
  # dotfiles.pip.globalPackagesFile = ".config/pip/global-packages.txt";

  # Bitwarden clients. The Dubnium workstation profile enables both by default;
  # use these explicit selections when maintaining a complete local config.
  # dotfiles.bitwarden.cli.enable = true;
  # dotfiles.bitwarden.desktop.enable = true;
  # Set either value to false to disable that client independently.

  # dotfiles.music.enable = false;
  # dotfiles.music.musicDirectory = "${config.home.homeDirectory}/Music";
  # dotfiles.grimblast.enable = false;
  # dotfiles.graphical.keyring.enable = false;
  # dotfiles.idle.enable = false;

  # Hardware/profile variants that are safe to select locally.
  # dotfiles.alacritty.adoptedProfile = "empty";
  # dotfiles.hypr.adoptedProfile = "empty";
  # dotfiles.waybar.variant = "workstation";

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

  # Personal read-only report scheduling and CareerOps contract inputs.
  # dotfiles.opsCadence.enable = false;
  # dotfiles.opsCadence.careerops.enable = true;
  # dotfiles.opsCadence.careerops.workflowsPath = "${config.home.homeDirectory}/.local/src/career-workflows";
  # dotfiles.opsCadence.careerops.stateDir = "${config.home.homeDirectory}/.local/state/careerops";
  # null uses <stateDir>/professional-context.v1.json.
  # dotfiles.opsCadence.careerops.professionalContextSnapshotPath = null;

  # Optional loopback Dubnium platform APIs. SQLite remains exact state.
  # dotfiles.opsCadence.platform.memory.enable = false;
  # dotfiles.opsCadence.platform.memory.baseUrl = "http://127.0.0.1:8090";
  # dotfiles.opsCadence.platform.memory.timeoutSeconds = 10;
  # dotfiles.opsCadence.platform.memory.scope = "workflow:ops-cadence";
  # dotfiles.opsCadence.platform.llm.enable = false;
  # dotfiles.opsCadence.platform.llm.baseUrl = "http://127.0.0.1:8080/v1";
  # dotfiles.opsCadence.platform.llm.model = "supervisor";
  # dotfiles.opsCadence.platform.llm.contractVersion = "dubnium.llm-gateway.v1";
  # dotfiles.opsCadence.platform.llm.timeoutSeconds = 60;
  # dotfiles.opsCadence.platform.scheduler.enable = false;
  # dotfiles.opsCadence.platform.scheduler.baseUrl = "http://127.0.0.1:8091";
  # dotfiles.opsCadence.platform.scheduler.timeoutSeconds = 10;
  # dotfiles.opsCadence.platform.scheduler.schedules = {
  #   career_intelligence = "ops-career-intelligence";
  #   engineering_portfolio = "ops-engineering-portfolio";
  #   weekly_review = "ops-weekly-review";
  # };
  # Enabling the Dubnium scheduler requires direct Home Manager timers to be disabled.
  # dotfiles.opsCadence.timers.enable = true;

  # dotfiles.opsCadence.liveSources.enable = false;
  # dotfiles.opsCadence.liveSources.gmail = false;
  # dotfiles.opsCadence.liveSources.github = false;
  # Runtime paths only; never place token contents in this file or the Nix store.
  # Enabling a live source requires its corresponding credential path.
  # dotfiles.opsCadence.credentials.githubTokenFile = "%h/.config/ops-cadence/secrets/github-token";
  # dotfiles.opsCadence.credentials.gmailAccessTokenFile = "%h/.config/ops-cadence/secrets/gmail-access-token";
  # dotfiles.opsCadence.timers.timeout = "15min";
  # dotfiles.opsCadence.timers.accuracy = "5min";
  # dotfiles.opsCadence.timers.randomizedDelay = "5min";

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
