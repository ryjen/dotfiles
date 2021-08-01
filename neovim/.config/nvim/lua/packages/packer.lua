
return require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- language server protocol
  use 'neovim/nvim-lspconfig'
  use 'kabouzeid/nvim-lspinstall' 
  use 'nvim-lua/completion-nvim'

  -- default keyboard layout
  use 'jooize/vim-colemak'

  -- debugger
  use 'mfussenegger/nvim-dap'
  use 'Pocco81/DAPInstall.nvim'
  use 'rcarriga/nvim-dap-ui'
  use 'theHamsta/nvim-dap-virtual-text'

  --- themes
  use 'altercation/vim-colors-solarized'

  -- Load on a combination of conditions: specific filetypes or commands
  -- Also run code after load (see the 'config' key)
  --use {
  --  'w0rp/ale',
  --  ft = {'sh', 'zsh', 'bash', 'c', 'cpp', 'cmake', 'html', 'markdown', 'vim', 'go', 'js'},
  --  cmd = 'ALEEnable',
  --  config = 'vim.cmd[[ALEEnable]]'
  --}

  -- Fuzzy finder
  use {
      'nvim-telescope/telescope.nvim',
      requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}}
  }


  -- Post-install/update hook with neovim command
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

end)


