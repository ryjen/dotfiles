{
  pkgs,
  ...
}:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;
      extensions = with pkgs.vscode-extensions; [
        bbenoist.nix
        jnoortheen.nix-ide
        mkhl.direnv
      ];
      userSettings = {
        "editor.fontSize" = 14;
        "editor.lineNumbers" = "relative";
        "editor.minimap.enabled" = false;
        "files.autoSave" = "onFocusChange";
        "workbench.startupEditor" = "none";
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
      };
    };
  };

  home.packages = with pkgs; [
    nil
    nixfmt
    marksman
    vscode-langservers-extracted
  ];
}
