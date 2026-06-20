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

    # External tools used by the Lua config and plugin integrations.
    # Keep this list explicit so Neovim behavior stays reproducible under Nix.
    extraPackages = with pkgs; [
      # Search & Navigation
      ripgrep
      fd
      fzf

      # Language Servers
      lua-language-server
      nil # Nix LSP
      pyright # Python LSP
      typescript-language-server

      # Formatters & Linters
      stylua
      nixfmt-rfc-style
      black
      ruff
      shfmt
      shellcheck
      prettier

      # Runtime support for plugins
      gcc # for tree-sitter and telescope-fzf-native
      nodejs
      git
    ];
  };

  # Declaratively symlink the config from the repo into the home directory.
  # Lua owns editor behavior; Home Manager owns installation and external tools.
  xdg.configFile."nvim" = {
    source = ../../files/home/.config/nvim;
    recursive = true;
  };

  xdg.configFile."nvim/local.lua".text = ''
    -- Local Neovim configuration.
    --
    -- Ownership:
    -- - machine-specific
    -- - writable by the user
    -- - never automatically promoted by configctl
  '';
}
