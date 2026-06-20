local ok, ts_configs = pcall(require, "nvim-treesitter.configs")
if not ok then
	vim.notify("nvim-treesitter is unavailable; skipping Treesitter setup", vim.log.levels.WARN)
	return
end

ts_configs.setup({
	ensure_installed = "all",
	highlight = { enable = true, use_languagetree = true },
	indent = { enable = false },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "gnn",
			node_incremental = "grn",
			scope_incremental = "grc",
			node_decremental = "grm",
		},
	},
})
