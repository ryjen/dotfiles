local utils = require("utils")
local dap_install = require("dap-install")

require("dapui").setup()

local opts = { noremap=true, silent=true }
local cmd = vim.cmd
local fn = vim.fn

cmd("command! DapContinue lua require'dap'.continue()<CR>")
cmd("command! DapStepOver lua require'dap'.step_over()<CR>")
cmd("command! DapStepInto lua require'dap'.step_into()<CR>")
cmd("command! DapStepOut lua require'dap'.step_out()<CR>")
cmd("command! DapBreak lua require'dap'.toggle_breakpoint()<CR>")
cmd("command! DapBreakOn lua require'dap'.set_breakpoint(fn.input('Breakpoint condition: '))<CR>")
cmd("command! DapLogPoint lua require'dap'.set_breakpoint(nil, nil, fn.input('Log point message: '))<CR>")
cmd("command! DapRepl lua require'dap'.repl.open()<CR>")
cmd("command! DapRun lua require'dap'.run_last()<CR>")
cmd("command! DapUI lua require'dapui'.toggle()<CR>")


utils.map( "n", "<leader>dc", ":DapContinue<CR>", opts)
utils.map( "n", "<leader>ds", ":DapStepOver<CR>", opts)
utils.map( "n", "<leader>di", ":DapStepInto<CR>", opts)
utils.map( "n", "<leader>do", ":DapStepOut<CR>", opts)
utils.map( "n", "<leader>db", ":DapBreak<CR>", opts)
utils.map( "n", "<leader>dB", ":DapBreakOn<CR>", opts)
utils.map( "n", "<leader>dp", ":DapLogPoint<CR>", opts)
utils.map( "n", "<leader>dr", ":DapRun<CR>", opts)
utils.map( "n", "<leader>du", ":DapUI<CR>", opts)

dap_install.setup({
	installation_path = fn.stdpath("data") .. "/dap-install/",
  verbosely_call_debuggers = false,
})

local dap_api = require("dap-install.api.debuggers")

for _,debugger in pairs(dap_api.get_installed_debuggers()) do
	dap_install.config(debugger, {})
end
