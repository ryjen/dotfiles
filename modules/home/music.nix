{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.music;

  # MuseScore 4.7.0 in nixos-26.05 is affected by a Qt 6.11 QML alias
  # regression that prevents dynamically-created dialogs such as New Score
  # from opening. Nixpkgs fixed this in its 4.7.4 package; keep the stable
  # package and carry the upstream fix only while the pinned version predates
  # that downstream fix.
  musescorePackage =
    if lib.versionOlder pkgs.musescore.version "4.7.4" then
      pkgs.musescore.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            url = "https://github.com/musescore/MuseScore/commit/f273501e418842351c4bda10cce32b0e329eaff1.patch";
            hash = "sha256-zrZRzeAHSFGtCuw/o4A3b1Blbo3FxKGxw1UDu9IggzY=";
          })
        ];
      })
    else
      pkgs.musescore;

  reaperPlugins = with pkgs; [
    dragonfly-reverb
    drumgizmo
    guitarix-vst
    lsp-plugins
    surge-xt
  ];

  # Not every plugin package ships every supported format. Build one stable
  # directory per format and include only the formats each package provides.
  pluginDirectory =
    format:
    pkgs.runCommand "reaper-${format}-plugins" { } ''
      mkdir -p "$out"

      for package in ${lib.escapeShellArgs (map toString reaperPlugins)}; do
        source="$package/lib/${format}"
        if [ ! -d "$source" ]; then
          continue
        fi

        for plugin in "$source"/*; do
          [ -e "$plugin" ] || continue
          ln -sfn "$plugin" "$out/$(basename "$plugin")"
        done
      done
    '';

  swsPluginName = "reaper_sws-${pkgs.stdenv.hostPlatform.uname.processor}.so";

  pluginSearchPaths = format: [
    "${config.home.homeDirectory}/.${format}"
    "${config.home.homeDirectory}/.nix-profile/lib/${format}"
    "/etc/profiles/per-user/${config.home.username}/lib/${format}"
    "/run/current-system/sw/lib/${format}"
  ];
in
{
  options.dotfiles.music = {
    enable = lib.mkEnableOption "local music playback and production tooling";

    musicDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Music";
      description = "Canonical directory for the managed music library.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      (with pkgs; [
        beets
        easyeffects
        hydrogen
        musescorePackage
        playerctl
        python3
        reaper
      ])
      ++ reaperPlugins;

    # mpv remains the general-purpose player for ad-hoc files, URLs and video.
    # Managed-library playback belongs to the optional MPD/rmpc layer.
    programs.mpv = {
      enable = true;

      scripts = with pkgs.mpvScripts; [
        mpris
      ];

      config = {
        audio-display = "no";
        save-position-on-quit = "yes";
      };
    };

    xdg.desktopEntries.guitar-pro-reader = {
      name = "Guitar Pro Reader";
      genericName = "Guitar Tablature Reader";
      comment = "Open and play Guitar Pro tablature with MuseScore";
      exec = "${musescorePackage}/bin/mscore %F";
      icon = "mscore";
      terminal = false;
      categories = [
        "Audio"
        "AudioVideo"
        "Music"
      ];
      mimeType = [
        "application/x-guitar-pro"
        "application/x-guitar-pro5"
      ];
    };

    # Populate the standard per-user plugin directories that REAPER scans.
    # Recursive linking allows unrelated manually installed plugins to coexist.
    home.file = {
      ".clap" = {
        source = pluginDirectory "clap";
        recursive = true;
      };
      ".lv2" = {
        source = pluginDirectory "lv2";
        recursive = true;
      };
      ".vst" = {
        source = pluginDirectory "vst";
        recursive = true;
      };
      ".vst3" = {
        source = pluginDirectory "vst3";
        recursive = true;
      };
    };

    # Also export the conventional search variables for other Linux audio hosts.
    home.sessionSearchVariables = {
      CLAP_PATH = pluginSearchPaths "clap";
      LV2_PATH = pluginSearchPaths "lv2";
      VST3_PATH = pluginSearchPaths "vst3";
      VST_PATH = pluginSearchPaths "vst";
    };

    # SWS is a REAPER extension rather than an audio plugin. Link its runtime
    # files into the REAPER resource directory while keeping the package immutable.
    xdg.configFile."REAPER/UserPlugins/${swsPluginName}".source =
      "${pkgs.reaper-sws-extension}/UserPlugins/${swsPluginName}";
    xdg.configFile."REAPER/Scripts/sws_python.py".source =
      "${pkgs.reaper-sws-extension}/Scripts/sws_python.py";
    xdg.configFile."REAPER/Scripts/sws_python64.py".source =
      "${pkgs.reaper-sws-extension}/Scripts/sws_python64.py";
  };
}
