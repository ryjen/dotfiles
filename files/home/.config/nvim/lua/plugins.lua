local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- Language server protocol. Language server binaries are installed by Home Manager.
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"folke/trouble.nvim",
			"ray-x/lsp_signature.nvim",
			"kosayoda/nvim-lightbulb",
			"hrsh7th/cmp-nvim-lsp",
		},
	},
	{
		"nvimtools/none-ls.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvimtools/none-ls-extras.nvim",
			"gbprod/none-ls-shellcheck.nvim",
		},
	},

	"fidian/hexmode",

	-- Completion.
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"L3MON4D3/LuaSnip",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lua",
			"saadparwaiz1/cmp_luasnip",
			"lukas-reineke/cmp-under-comparator",
			"hrsh7th/cmp-nvim-lsp-document-symbol",
		},
		config = function()
			require("config.cmp")
		end,
	},

	-- Themes.
	"altercation/vim-colors-solarized",

	-- Bufferline.
	{
		"akinsho/nvim-bufferline.lua",
		event = "User ActuallyEditing",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("config.bufferline")
		end,
	},

	-- Fuzzy finder.
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
			{
				"nvim-telescope/telescope-frecency.nvim",
				dependencies = { "kkharji/sqlite.lua" },
			},
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
		},
		init = function()
			require("config.telescope_setup")
		end,
		config = function()
			require("config.telescope")
		end,
	},

	-- Syntax tree support.
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
	},

	-- Default keyboard layout.
	"jooize/vim-colemak",
}, {
	checker = { enabled = false },
	install = { missing = true },
	change_detection = { notify = false },
})
