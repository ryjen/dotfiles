local packer = nil
local function init()
	if packer == nil then
		packer = require("packer")
		packer.init({ disable_commands = true })
	end

	local use = packer.use
	packer.reset()

	-- Packer can manage itself.
	use("wbthomason/packer.nvim")

	-- Language server protocol.
	use({
		"neovim/nvim-lspconfig",
		"folke/trouble.nvim",
		"ray-x/lsp_signature.nvim",
		"kosayoda/nvim-lightbulb",
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
	})
	use({ "nvimtools/none-ls.nvim", requires = { "nvim-lua/plenary.nvim" } })

	use("fidian/hexmode")

	-- Completion.
	use({
		"hrsh7th/nvim-cmp",
		requires = {
			"L3MON4D3/LuaSnip",
			{ "hrsh7th/cmp-buffer", after = "nvim-cmp" },
			{ "hrsh7th/cmp-nvim-lsp", after = "nvim-cmp" },
			{ "hrsh7th/cmp-nvim-lsp-signature-help", after = "nvim-cmp" },
			{ "hrsh7th/cmp-path", after = "nvim-cmp" },
			{ "hrsh7th/cmp-nvim-lua", after = "nvim-cmp" },
			{ "saadparwaiz1/cmp_luasnip", after = "nvim-cmp" },
			"lukas-reineke/cmp-under-comparator",
			{ "hrsh7th/cmp-nvim-lsp-document-symbol", after = "nvim-cmp" },
		},
		config = [[require('config.cmp')]],
		event = "InsertEnter *",
	})

	-- Themes.
	use("altercation/vim-colors-solarized")

	-- Bufferline.
	use({
		"akinsho/nvim-bufferline.lua",
		requires = "nvim-tree/nvim-web-devicons",
		config = [[require('config.bufferline')]],
		event = "User ActuallyEditing",
	})

	-- Fuzzy finder.
	use({
		{
			"nvim-telescope/telescope.nvim",
			requires = {
				"nvim-lua/plenary.nvim",
				"telescope-frecency.nvim",
				"telescope-fzf-native.nvim",
				"nvim-telescope/telescope-ui-select.nvim",
			},
			wants = {
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

	-- Post-install/update hook with neovim command.
	use({
		"nvim-treesitter/nvim-treesitter",
		requires = {
			"nvim-treesitter/nvim-treesitter-refactor",
			"RRethy/nvim-treesitter-textsubjects",
		},
		run = ":TSUpdate",
	})

	-- Default keyboard layout.
	use("jooize/vim-colemak")
end

local plugins = setmetatable({}, {
	__index = function(_, key)
		init()
		return packer[key]
	end,
})

return plugins
