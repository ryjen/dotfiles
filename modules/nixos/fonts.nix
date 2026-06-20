{
  pkgs,
  ...
}:
{
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; }) # optional, for mono
    (pkgs.dejavu_fonts) # usually already present, but ok to keep
    (pkgs.inter)       # optional: install Inter
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
