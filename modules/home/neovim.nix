{
  pkgs,
  ...
}:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraLuaConfig = ''
      -- Colemak keymappings (HNEI)
      
      -- Basic Directional
      vim.keymap.set({'n', 'v'}, 'n', 'j')
      vim.keymap.set({'n', 'v'}, 'e', 'k')
      vim.keymap.set({'n', 'v'}, 'i', 'l')
      -- h is h

      -- Steal remappings
      vim.keymap.set({'n', 'v'}, 'k', 'i') -- i -> k
      vim.keymap.set({'n', 'v'}, 'j', 'n') -- n -> j
      vim.keymap.set({'n', 'v'}, 'l', 'e') -- e -> l
      
      -- CTRL faster navigation
      vim.keymap.set({'n', 'v'}, '<C-h>', '5h')
      vim.keymap.set({'n', 'v'}, '<C-n>', '5j')
      vim.keymap.set({'n', 'v'}, '<C-e>', '5k')
      vim.keymap.set({'n', 'v'}, '<C-i>', '5l')

      -- Insert mode directional
      vim.keymap.set('i', '<C-h>', '<Left>')
      vim.keymap.set('i', '<C-n>', '<Down>')
      vim.keymap.set('i', '<C-e>', '<Up>')
      vim.keymap.set('i', '<C-i>', '<Right>')
    '';

    # These packages are the external dependencies your plugins need
    extraPackages = with pkgs; [
      # Search & Navigation
      ripgrep
      fd
      fzf

      # Language Servers & Tooling
      lua-language-server
      nil # Nix LSP
      pyright # Python LSP
      nodePackages.typescript-language-server

      # Runtime support for plugins
      gcc # for tree-sitter
      nodejs
      git
    ];
  };

  # Declaratively symlink the config from the repo into the home directory
  xdg.configFile."nvim" = {
    source = ../../files/home/.config/nvim;
    recursive = true;
  };
}
