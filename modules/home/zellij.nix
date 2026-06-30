{
  pkgs,
  lib,
  ...
}:
{
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    settings = {
      default_mode = "locked";
      default_shell = "/bin/zsh";
      simplified_ui = true;
      true_color = true;
      mouse_mode = true;
      auto_layout = false;
      theme = "default";
    };
    extraConfig = ''
      keybinds {
        normal {
          bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
          bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
          bind "Alt k" "Alt Up" { MoveFocusOrTab "Up"; }
          bind "Alt j" "Alt Down" { MoveFocusOrTab "Down"; }
          bind "Ctrl h" { MoveFocus "Left"; }
          bind "Ctrl l" { MoveFocus "Right"; }
          bind "Ctrl k" { MoveFocus "Up"; }
          bind "Ctrl j" { MoveFocus "Down"; }
        }
        locked {
          bind "Ctrl g" { SwitchToMode "normal"; }
        }
      }
    '';
    enableZshIntegration = false;
  };
}
