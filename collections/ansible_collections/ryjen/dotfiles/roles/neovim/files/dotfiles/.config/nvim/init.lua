vim.loader.enable()

local g = vim.g
local cmd = vim.cmd

-- Disable some built-in plugins we don't want
local disabled_built_ins = {
	"gzip",
	"man",
	"matchit",
	"matchparen",
	"shada_plugin",
	"tarPlugin",
	"tar",
	"zipPlugin",
	"zip",
	"netrwPlugin",
}

for i = 1, 10 do
	g["loaded_" .. disabled_built_ins[i]] = 1
end

-- Sensible defaults
require("settings")

-- Commands
cmd([[command! PackerInstall packadd packer.nvim | lua require('plugins').install()]])
cmd([[command! PackerUpdate packadd packer.nvim | lua require('plugins').update()]])
cmd([[command! PackerSync packadd packer.nvim | lua require('plugins').sync()]])
cmd([[command! PackerClean packadd packer.nvim | lua require('plugins').clean()]])
cmd([[command! PackerCompile packadd packer.nvim | lua require('plugins').compile()]])

-- Auto compile when there are changes in plugins.lua
cmd("autocmd BufWritePost plugins.lua PackerCompile")

-- Key mappings
require("keymappings")

-- Another option is to groups configuration in one folder
require("config")
