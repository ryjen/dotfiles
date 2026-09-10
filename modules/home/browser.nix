{
  lib,
  pkgs,
  config,
  ...
}:
let
  chatgptLauncher = pkgs.writeShellApplication {
    name = "dub-chatgpt";
    runtimeInputs = [
      pkgs.chromium
      pkgs.coreutils
      pkgs.uwsm
    ];
    text = ''
      profile_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/chromium-chatgpt"
      install -d -m 0700 "$profile_dir"

      args=(
        "--user-data-dir=$profile_dir"
        "--app=https://chatgpt.com"
        "--no-first-run"
        "--no-default-browser-check"
      )

      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        args+=("--ozone-platform=wayland")
        exec uwsm app -- chromium "''${args[@]}"
      fi

      exec chromium "''${args[@]}"
    '';
  };
in
{
  options.dotfiles.profiles.browser.enable = lib.mkEnableOption "browser profile";

  config = lib.mkIf config.dotfiles.profiles.browser.enable {
    home.packages = [
      chatgptLauncher
    ];

    home.sessionVariables = {
      BROWSER = "firefox";
      DEFAULT_BROWSER = "firefox";
    };

    programs.firefox = {
      enable = true;
      configPath = ".mozilla/firefox";
      package = pkgs.firefox;

      policies = {
        DisableFirefoxAccounts = false;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DNSOverHTTPS.Enabled = false;
        DontCheckDefaultBrowser = true;
        ExtensionSettings = {
          "{446900e4-71c2-419f-a6a7-9bba13b1a889}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          };
        };
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;
      };

      profiles.dubnium = {
        id = 0;
        isDefault = true;
        name = "dubnium";
        search.force = true;
        search.default = "ddg";
        settings = {
          "browser.aboutConfig.showWarning" = false;
          "browser.contentblocking.category" = "strict";
          "browser.download.useDownloadDir" = false;
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.tabs.warnOnClose" = true;
          "browser.uidensity" = 1;
          "datareporting.healthreport.uploadEnabled" = false;
          "dom.security.https_only_mode" = true;
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          "media.eme.enabled" = true;
          "privacy.donottrackheader.enabled" = true;
          "privacy.globalprivacycontrol.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "signon.rememberSignons" = false;
          "toolkit.telemetry.enabled" = false;
        };
      };
    };

    xdg.desktopEntries.chatgpt = {
      name = "ChatGPT";
      genericName = "AI Assistant";
      comment = "ChatGPT in a dedicated Chromium profile";
      exec = "${chatgptLauncher}/bin/dub-chatgpt";
      icon = "chromium";
      terminal = false;
      categories = [
        "Network"
        "Utility"
      ];
      settings.Keywords = "ChatGPT;OpenAI;AI;";
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/x-gnome-saved-search" = "org.gnome.Nautilus.desktop";
        "inode/directory" = "org.gnome.Nautilus.desktop";
        "text/html" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
      };
    };
  };
}
