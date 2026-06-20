{
  pkgs,
  ...
}:
{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    dejavu_fonts
    inter
  ];

  fonts.fontconfig = {
    enable = true;
    antialias = true;
    defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" ];
      sansSerif = [ "Inter" ];
      serif = [ "DejaVu Serif" ];
    };
  };
}
