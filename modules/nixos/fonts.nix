{
  pkgs,
  ...
}:
{
  fonts.packages = with pkgs; [
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    dejavu_fonts
    inter
  ];

  fonts.fontconfig = {
    enable = true;
    antialias = true;
    defaultFonts = {
      monospace = [
        "Hack Nerd Font Mono"
        "JetBrainsMono Nerd Font Mono"
        "JetBrainsMono Nerd Font"
        "Symbols Nerd Font Mono"
      ];
      sansSerif = [ "Inter" ];
      serif = [ "DejaVu Serif" ];
    };
  };
}
