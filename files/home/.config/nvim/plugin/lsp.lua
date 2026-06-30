local function optional_require(module)
	local ok, value = pcall(require, module)
	if ok then
		return value
	end
	return nil
end

local trouble = optional_require("trouble")
if trouble then
	trouble.setup()
end

local lsp_signature = optional_require("lsp_signature")
if lsp_signature then
	lsp_signature.setup({ bind = true, handler_opts = { border = "single" } })
end

pcall(vim.api.nvim_command, "hi link LightBulbFloatWin YellowFloat")
pcall(vim.api.nvim_command, "hi link LightBulbVirtualText YellowFloat")

vim.diagnostic.config({
	virtual_text = false,
	signs = true,
	update_in_insert = false,
	underline = true,
})

local keymap_opts = { noremap = true, silent = true }

local function telescope_or_lsp(telescope_fn, lsp_fn)
	return function()
		local telescope = optional_require("telescope.builtin")
		if telescope and telescope[telescope_fn] then
			telescope[telescope_fn]()
		else
			vim.lsp.buf[lsp_fn]()
		end
	end
end

local function on_attach(client, bufnr)
	if lsp_signature then
		lsp_signature.on_attach({ bind = true, handler_opts = { border = "single" } }, bufnr)
	end

	local function map(mode, lhs, rhs)
		vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", keymap_opts, { buffer = bufnr }))
	end

	map("n", "gD", vim.lsp.buf.declaration)
	map("n", "gd", telescope_or_lsp("lsp_definitions", "definition"))
	map("n", "K", vim.lsp.buf.hover)
	map("n", "gi", telescope_or_lsp("lsp_implementations", "implementation"))
	map("n", "gS", vim.lsp.buf.signature_help)
	map("n", "gTD", vim.lsp.buf.type_definition)
	map("n", "<leader>rn", vim.lsp.buf.rename)
	map("n", "gr", telescope_or_lsp("lsp_references", "references"))
	map({ "n", "v" }, "gA", vim.lsp.buf.code_action)
	map("n", "]e", function()
		vim.diagnostic.goto_next({ float = true })
	end)
	map("n", "[e", function()
		vim.diagnostic.goto_prev({ float = true })
	end)

	if client.server_capabilities and client.server_capabilities.documentFormattingProvider then
		map("n", "<leader>f", function()
			vim.lsp.buf.format({ async = true, bufnr = bufnr })
		end)
	end

	local group_name = "dotfiles_lsp_" .. bufnr .. "_" .. client.id
	local lsp_aucmds = vim.api.nvim_create_augroup(group_name, { clear = true })

	if client.server_capabilities and client.server_capabilities.documentHighlightProvider then
		vim.api.nvim_create_autocmd("CursorHold", {
			group = lsp_aucmds,
			buffer = bufnr,
			callback = vim.lsp.buf.document_highlight,
		})
		vim.api.nvim_create_autocmd("CursorMoved", {
			group = lsp_aucmds,
			buffer = bufnr,
			callback = vim.lsp.buf.clear_references,
		})
	end

	if client.supports_method and client:supports_method("textDocument/formatting") then
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = lsp_aucmds,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format({ bufnr = bufnr })
			end,
		})
	end

	local lightbulb = optional_require("nvim-lightbulb")
	if lightbulb then
		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			group = lsp_aucmds,
			buffer = bufnr,
			callback = function()
				lightbulb.update_lightbulb({
					sign = { enabled = false },
					virtual_text = { enabled = true, text = "" },
					float = {
						enabled = false,
						text = "",
						win_opts = { winblend = 100, anchor = "NE" },
					},
				})
			end,
		})
	end
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
local cmp_nvim_lsp = optional_require("cmp_nvim_lsp")
if cmp_nvim_lsp then
	capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

local function configure_lsp(server, config)
	config = vim.tbl_extend("force", {
		on_attach = on_attach,
		capabilities = capabilities,
	}, config or {})

	if vim.lsp.config then
		vim.lsp.config(server, config)
		vim.lsp.enable(server)
		return
	end

	-- Compatibility fallback for older Neovim/lspconfig combinations.
	local lspconfig = optional_require("lspconfig")
	if lspconfig and lspconfig[server] then
		lspconfig[server].setup(config)
	end
end

-- Server executables are installed by Home Manager in modules/home/neovim.nix.
configure_lsp("lua_ls", {})
configure_lsp("nil_ls", {})
configure_lsp("pyright", {})
configure_lsp("ts_ls", {})

vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("dotfiles_trim_whitespace", { clear = true }),
	pattern = "*",
	callback = function()
		local save = vim.fn.winsaveview()
		vim.cmd([[%s/\s\+$//e]])
		vim.cmd([[%s#\($\n\s*\)\+\%$##e]])
		vim.fn.winrestview(save)
	end,
})

local null_ls = optional_require("null-ls")
if null_ls then
	local sources = {}
	local function add(source)
		if source then
			table.insert(sources, source)
		end
	end

	local formatting = null_ls.builtins.formatting

	add(formatting.stylua)
	add(formatting.nixfmt)
	add(formatting.black)
	add(formatting.shfmt)
	add(formatting.prettier)

	add(optional_require("none-ls.formatting.ruff"))
	add(optional_require("none-ls.diagnostics.ruff"))
	add(optional_require("none-ls-shellcheck.diagnostics"))
	add(optional_require("none-ls-shellcheck.code_actions"))

	null_ls.setup({
		sources = sources,
		on_attach = on_attach,
	})
end
