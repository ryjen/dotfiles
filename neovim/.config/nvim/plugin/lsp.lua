require("trouble").setup()
require("mason").setup()
require("mason-lspconfig").setup()

local lsp = vim.lsp
local cmd = vim.cmd
local buf_keymap = vim.api.nvim_buf_set_keymap
local lspconfig = require("lspconfig")
local null_ls = require("null-ls")

vim.api.nvim_command("hi link LightBulbFloatWin YellowFloat")
vim.api.nvim_command("hi link LightBulbVirtualText YellowFloat")

lsp.handlers["textDocument/publishDiagnostics"] = lsp.with(lsp.diagnostic.on_publish_diagnostics, {
	virtual_text = false,
	signs = true,
	update_in_insert = false,
	underline = true,
})

require("lsp_signature").setup({ bind = true, handler_opts = { border = "single" } })
local keymap_opts = { noremap = true, silent = true }

local function on_attach(client)
	require("lsp_signature").on_attach({ bind = true, handler_opts = { border = "single" } })
	buf_keymap(0, "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", keymap_opts)
	buf_keymap(0, "n", "gd", '<cmd>lua require"telescope.builtin".lsp_definitions()<CR>', keymap_opts)
	buf_keymap(0, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", keymap_opts)
	buf_keymap(0, "n", "gi", '<cmd>lua require"telescope.builtin".lsp_implementations()<CR>', keymap_opts)
	buf_keymap(0, "n", "gS", "<cmd>lua vim.lsp.buf.signature_help()<CR>", keymap_opts)
	buf_keymap(0, "n", "gTD", "<cmd>lua vim.lsp.buf.type_definition()<CR>", keymap_opts)
	buf_keymap(0, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", keymap_opts)
	buf_keymap(0, "n", "gr", '<cmd>lua require"telescope.builtin".lsp_references()<CR>', keymap_opts)
	buf_keymap(0, "n", "gA", "<cmd>lua vim.lsp.buf.code_action()<CR>", keymap_opts)
	buf_keymap(0, "v", "gA", "<cmd>lua vim.lsp.buf.code_action()<CR>", keymap_opts)
	buf_keymap(0, "n", "]e", "<cmd>lua vim.diagnostic.goto_next { float = true }<cr>", keymap_opts)
	buf_keymap(0, "n", "[e", "<cmd>lua vim.diagnostic.goto_prev { float = true }<cr>", keymap_opts)

	if client.server_capabilities.documentFormattingProvider then
		buf_keymap(0, "n", "<leader>f", "<cmd>lua vim.lsp.buf.format { async = true }<cr>", keymap_opts)
	end
	cmd("augroup lsp_aucmds")
	if client.server_capabilities.documentHighlightProvider then
		cmd("au CursorHold <buffer> lua vim.lsp.buf.document_highlight()")
		cmd("au CursorMoved <buffer> lua vim.lsp.buf.clear_references()")
	end
	if client.supports_method("textDocument/formatting") then
		vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = augroup,
			buffer = bufnr,
			callback = function()
				-- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
				--lsp.buf.formatting_sync()
				lsp.buf.format({ bufner = bufnr })
			end,
		})
	end
	cmd(
		'au CursorHold,CursorHoldI <buffer> lua require"nvim-lightbulb".update_lightbulb {sign = {enabled = false}, virtual_text = {enabled = true, text = ""}, float = {enabled = false, text = "", win_opts = {winblend = 100, anchor = "NE"}}}'
	)
	-- cmd 'au CursorHold,CursorHoldI <buffer> lua vim.diagnostic.open_float(0, { scope = "line" })'
	cmd("augroup END")
end

lspconfig.util.default_config = vim.tbl_extend("force", lspconfig.util.default_config, { on_attach = on_attach })

-- null-ls setup
local null_fmt = null_ls.builtins.formatting
local null_diag = null_ls.builtins.diagnostics
local null_act = null_ls.builtins.code_actions
null_ls.setup({
	sources = {
		null_diag.chktex,
		null_diag.cppcheck,
		--null_diag.proselint,
		null_diag.pylint,
		null_diag.selene,
		null_diag.shellcheck,
		--null_diag.teal,
		--null_diag.vale,
		null_diag.ansiblelint,
		null_diag.checkmake,
		null_diag.clang_check,
		null_diag.codespell,
		null_diag.gitlint,
		null_diag.credo,
		--null_diag.cspell,
		null_diag.curlylint,
		null_diag.djlint,
		null_diag.editorconfig_checker,
		null_diag.eslint,
		null_diag.ktlint,
		null_diag.markdownlint,
		null_diag.zsh,
		null_diag.vint,
		null_diag.php,
		null_diag.pylint,
		null_diag.revive,
		--null_diag.semgrep,
		null_diag.write_good.with({ filetypes = { "markdown", "tex" } }),
		null_fmt.clang_format,
		null_fmt.cmake_format,
		null_fmt.isort,
		null_fmt.djlint,
		null_fmt.eslint_d,
		null_fmt.gofmt,
		null_fmt.jq,
		null_fmt.markdownlint,
		null_fmt.perltidy,
		null_fmt.ktlint,
		null_fmt.sqlformat,
		null_fmt.terrafmt,
		null_fmt.trim_whitespace,
		null_fmt.trim_newlines,
		null_fmt.goimports,
		null_fmt.prettier,
		null_fmt.rustfmt,
		null_fmt.shfmt,
		null_fmt.stylua,
		null_fmt.trim_whitespace,
		null_fmt.yapf,
		null_fmt.black,
		null_act.eslint,
		null_act.shellcheck,
		null_act.refactoring.with({ filetypes = { "javascript", "typescript", "lua", "python", "c", "cpp" } }),
	},
	on_attach = on_attach,
})
