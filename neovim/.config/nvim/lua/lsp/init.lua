local nvim_lsp = require("lspconfig")
local lsp_install = require("lspinstall")

local format_async = function(err, _, result, _, bufnr)
    if err ~= nil or result == nil then return end
    if not vim.api.nvim_buf_get_option(bufnr, "modified") then
        local view = vim.fn.winsaveview()
        vim.lsp.util.apply_text_edits(result, bufnr)
        vim.fn.winrestview(view)
        if bufnr == vim.api.nvim_get_current_buf() then
            vim.api.nvim_command("noautocmd :update")
        end
    end
end

vim.lsp.handlers["textDocument/formatting"] = format_async

local on_attach = function(client, bufnr)
    require('completion').on_attach()

    local opts = { noremap=true, silent=true }
    local buf_map = vim.api.nvim_buf_set_keymap
    local cmd = vim.cmd
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    cmd("command! LspDef lua vim.lsp.buf.definition()")
    cmd("command! LspDec lua vim.lsp.buf.declaration()")
    cmd("command! LspFormatting lua vim.lsp.buf.formatting()")
    cmd("command! LspCodeAction lua vim.lsp.buf.code_action()")
    cmd("command! LspHover lua vim.lsp.buf.hover()")
    cmd("command! LspRename lua vim.lsp.buf.rename()")
    cmd("command! LspRefs lua vim.lsp.buf.references()")
    cmd("command! LspTypeDef lua vim.lsp.buf.type_definition()")
    cmd("command! LspImplementation lua vim.lsp.buf.implementation()")
    cmd("command! LspDiagPrev lua vim.lsp.diagnostic.goto_prev()")
    cmd("command! LspDiagNext lua vim.lsp.diagnostic.goto_next()")
    cmd("command! LspDiagLine lua vim.lsp.diagnostic.show_line_diagnostics()")
    cmd("command! LspSignatureHelp lua vim.lsp.buf.signature_help()")

    buf_map(bufnr, "n", "gd", ":LspDef<CR>", opts)
    buf_map(bufnr, "n", "gD", ":LspDec<CR>", opts)
    buf_map(bufnr, "n", "gr", ":LspRename<CR>", opts)
    buf_map(bufnr, "n", "gR", ":LspRefs<CR>", opts)
    buf_map(bufnr, "n", "gy", ":LspTypeDef<CR>", opts)
    buf_map(bufnr, "n", "K", ":LspHover<CR>", opts)
    buf_map(bufnr, "n", "[a", ":LspDiagPrev<CR>", opts)
    buf_map(bufnr, "n", "]a", ":LspDiagNext<CR>", opts)
    buf_map(bufnr, "n", "ga", ":LspCodeAction<CR>", opts)
    buf_map(bufnr, "n", "<Leader>a", ":LspDiagLine<CR>", opts)
    buf_map(bufnr, "i", "<C-x><C-x>", "<cmd> LspSignatureHelp<CR>", opts)

    if client.resolved_capabilities.document_formatting then
        vim.api.nvim_exec([[
         augroup LspAutocommands
             autocmd! * <buffer>
             autocmd BufWritePost <buffer> LspFormatting
         augroup END
         ]], true)
    end
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    'documentation',
    'detail',
    'additionalTextEdits',
  }
}

lsp_install.setup()

local servers = lsp_install.installed_servers()
for _, server in pairs(servers) do
  nvim_lsp[server].setup{
    on_attach = on_attach,
    capabilities = capabilities,
    flags = {
      debounce_text_changes = 150,
    }
  }
end
