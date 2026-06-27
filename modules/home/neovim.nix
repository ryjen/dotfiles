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
    withRuby = true;
    withPython3 = true;

    extraPackages = with pkgs; [
      ripgrep
      fd
      fzf
      lua-language-server
      nil
      pyright
      typescript-language-server
      stylua
      nixfmt-rfc-style
      black
      ruff
      shfmt
      shellcheck
      prettier
      gcc
      nodejs
      git
    ];
  };

  xdg.configFile."nvim" = {
    source = ../../files/home/.config/nvim;
    recursive = true;
  };

  xdg.configFile."nvim/local.lua".text = ''
    -- Local Neovim configuration.
  '';
}
