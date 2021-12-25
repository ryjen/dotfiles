local nvim_lsp = require("lspconfig")
local lsp_install = require("lspinstall")

local format_async = function(err, result, ctx, _)
    if err ~= nil or result == nil then return end
    if not vim.api.nvim_buf_get_option(ctx.bufnr, "modified") then
        local view = vim.fn.winsaveview()
        vim.lsp.util.apply_text_edits(result, ctx.bufnr)
        vim.fn.winrestview(view)
        if ctx.bufnr == vim.api.nvim_get_current_buf() then
            vim.api.nvim_command("noautocmd :update")
        end
    end
end

vim.lsp.handlers["textDocument/formatting"] = format_async


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

function goimports(timeout_ms)
    local context = { only = { "source.organizeImports" } }
    vim.validate { context = { context, "t", true } }

    local params = vim.lsp.util.make_range_params()
    params.context = context

    -- See the implementation of the textDocument/codeAction callback
    -- (lua/vim/lsp/handler.lua) for how to do this properly.
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, timeout_ms)
    if not result or next(result) == nil then return end
    local actions = result[1].result
    if not actions then return end
    local action = actions[1]

    -- textDocument/codeAction can return either Command[] or CodeAction[]. If it
    -- is a CodeAction, it can have either an edit, a command or both. Edits
    -- should be executed first.
    if action.edit or type(action.command) == "table" then
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit)
      end
      if type(action.command) == "table" then
        vim.lsp.buf.execute_command(action.command)
      end
    else
      vim.lsp.buf.execute_command(action)
    end
  end

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
             autocmd BufWritePre *.go lua goimports(1000)
             autocmd BufWritePost <buffer> LspFormatting
         augroup END
         ]], true)
    end
end

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

