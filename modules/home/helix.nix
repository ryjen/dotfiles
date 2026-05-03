{
  pkgs,
  ...
}:
{
  programs.helix = {
    enable = true;
    # Neovim owns EDITOR/VISUAL (programs.neovim.defaultEditor).
    defaultEditor = false;
    settings = {
      theme = "solarized_dark";
      editor = {
        line-number = "relative";
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        lsp.display-messages = true;
      };
      keys.normal = {
        # HNEI navigation
        h = "move_char_left";
        n = "move_line_down";
        e = "move_line_up";
        i = "move_char_right";
        
        # Original n (search next) -> j
        j = "search_next";
        J = "search_prev";
        
        # Original e (end of word) -> l
        l = "move_word_forward";
        L = "move_word_backward";
        
        # Original i (insert) -> k
        k = "insert_mode";
        K = "insert_at_line_start";
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
        }
      ];
    };
  };

  # Extra LSPs that Helix uses
  home.packages = with pkgs; [
    nil
    nixfmt-rfc-style
    marksman # Markdown LSP
    vscode-langservers-extracted # HTML/CSS/JSON
  ];
}
