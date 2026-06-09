{
  ...
}:
let
  terminalFont = "JetBrainsMono Nerd Font Mono";
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        size = 18;
        normal = {
          family = terminalFont;
          style = "Regular";
        };
        bold = {
          family = terminalFont;
          style = "Bold";
        };
        italic = {
          family = terminalFont;
          style = "Italic";
        };
        bold_italic = {
          family = terminalFont;
          style = "Bold Italic";
        };
        offset = {
          x = 0;
          y = 0;
        };
        glyph_offset = {
          x = 0;
          y = 0;
        };
      };
    };
  };
}
