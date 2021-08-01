
return require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use 'neovim/nvim-lspconfig'
  use 'kabouzeid/nvim-lspinstall' 
 
  use 'jooize/vim-colemak'

  use 'mfussenegger/nvim-dap'
  use "Pocco81/DAPInstall.nvim"

  --- themes
  use 'altercation/vim-colors-solarized'

  -- Load on a combination of conditions: specific filetypes or commands
  -- Also run code after load (see the 'config' key)
  use {
    'w0rp/ale',
    ft = {'sh', 'zsh', 'bash', 'c', 'cpp', 'cmake', 'html', 'markdown', 'vim', 'go', 'js'},
    cmd = 'ALEEnable',
    config = 'vim.cmd[[ALEEnable]]'
  }

  use 'glepnir/lspsaga.nvim'
  use { 'nvim-lua/completion-nvim' }

  -- Fuzzy finder
  use {
      'nvim-telescope/telescope.nvim',
      requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}}
  }


  -- Post-install/update hook with neovim command
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

end)


