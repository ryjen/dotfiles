local packer = nil
local function init()
	if packer == nil then
		packer = require("packer")
		packer.init({ disable_commands = true })
	end

	local use = packer.use
	packer.reset()

	-- Packer can manage itself
	use("wbthomason/packer.nvim")

	-- language server protocol
	use({
		"neovim/nvim-lspconfig",
		"folke/trouble.nvim",
		"ray-x/lsp_signature.nvim",
		"kosayoda/nvim-lightbulb",
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
	})
	use({ "jose-elias-alvarez/null-ls.nvim", requires = { "nvim-lua/plenary.nvim" } })

	use("lewis6991/impatient.nvim")

	-- Completion
	use({
		"hrsh7th/nvim-cmp",
		requires = {
			"L3MON4D3/LuaSnip",
			{ "hrsh7th/cmp-buffer", after = "nvim-cmp" },
			"hrsh7th/cmp-nvim-lsp",
			--'hrsh7th/cmp-nvim-lsp-signature-help',
			{ "hrsh7th/cmp-path", after = "nvim-cmp" },
			{ "hrsh7th/cmp-nvim-lua", after = "nvim-cmp" },
			{ "saadparwaiz1/cmp_luasnip", after = "nvim-cmp" },
			"lukas-reineke/cmp-under-comparator",
			{ "hrsh7th/cmp-nvim-lsp-document-symbol", after = "nvim-cmp" },
		},
		config = [[require('config.cmp')]],
		event = "InsertEnter *",
	})

	-- Debugger
	use({
		{
			"mfussenegger/nvim-dap",
			setup = [[require('config.dap_setup')]],
			config = [[require('config.dap')]],
			requires = "jbyuki/one-small-step-for-vimkind",
			wants = "one-small-step-for-vimkind",
			module = "dap",
		},
		{
			"rcarriga/nvim-dap-ui",
			requires = "nvim-dap",
			after = "nvim-dap",
			config = function()
				require("dapui").setup()
			end,
		},
	})
	--- themes
	use("altercation/vim-colors-solarized")

	-- lsp icons
	-- use 'onsails/lspkind-nvim'

	-- utils
	use({
		"chaoren/vim-wordmotion",
		setup = [[require('config.wordmotion')]],
	})
	--use 'kevinhwang91/nvim-bqf'
	use({
		"mg979/vim-visual-multi",
		config = [[require('config.visualmulti')]],
	})

	-- file tree
	use({
		"kyazdani42/nvim-tree.lua",
		requires = "kyazdani42/nvim-web-devicons",
	})

	-- line endings and space indicators
	-- use "lukas-reineke/indent-blankline.nvim"

	-- status bar
	-- use 'glepnir/galaxyline.nvim'

	-- use 'windwp/nvim-autopairs'

	use({
		"akinsho/nvim-bufferline.lua",
		requires = "kyazdani42/nvim-web-devicons",
		config = [[require('config.bufferline')]],
		event = "User ActuallyEditing",
	})

	-- Load on a combination of conditions: specific filetypes or commands
	-- Also run code after load (see the 'config' key)
	--use {
	--  'w0rp/ale',
	--  ft = {'sh', 'zsh', 'bash', 'c', 'cpp', 'cmake', 'html', 'markdown', 'vim', 'go', 'js'},
	--  cmd = 'ALEEnable',
	--  config = 'vim.cmd[[ALEEnable]]'
	--}

	-- Fuzzy finder
	use({
		{
			"nvim-telescope/telescope.nvim",
			requires = {
				"nvim-lua/popup.nvim",
				"nvim-lua/plenary.nvim",
				"telescope-frecency.nvim",
				"telescope-fzf-native.nvim",
				"nvim-telescope/telescope-ui-select.nvim",
			},
			wants = {
				"popup.nvim",
				"plenary.nvim",
				"telescope-frecency.nvim",
				"telescope-fzf-native.nvim",
			},
			setup = [[require('config.telescope_setup')]],
			config = [[require('config.telescope')]],
			cmd = "Telescope",
			module = "telescope",
		},
		{
			"nvim-telescope/telescope-frecency.nvim",
			after = "telescope.nvim",
			requires = "tami5/sqlite.lua",
		},
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			run = "make",
		},
	})

	-- Documentation
	use({
		"danymat/neogen",
		requires = "nvim-treesitter",
		config = [[require('config.neogen')]],
		keys = { "<leader>d", "<leader>df", "<leader>dc" },
	})

	-- Post-install/update hook with neovim command
	use({
		"nvim-treesitter/nvim-treesitter",
		requires = {
			"nvim-treesitter/nvim-treesitter-refactor",
			"RRethy/nvim-treesitter-textsubjects",
		},
		run = ":TSUpdate",
	})

	-- default keyboard layout
	use("jooize/vim-colemak")
end

local plugins = setmetatable({}, {
	__index = function(_, key)
		init()
		return packer[key]
	end,
})

return plugins
