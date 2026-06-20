vim.loader.enable()

local g = vim.g
local fn = vim.fn

-- Disable some built-in plugins we don't want.
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

for _, plugin in ipairs(disabled_built_ins) do
	g["loaded_" .. plugin] = 1
end

local function safe_require(module)
	local ok, err = pcall(require, module)
	if not ok then
		vim.notify("Failed to load " .. module .. ": " .. err, vim.log.levels.WARN)
	end
end

local function source_lua_file(path)
	local expanded = fn.expand(path)
	if fn.filereadable(expanded) == 1 then
		local ok, err = pcall(dofile, expanded)
		if not ok then
			vim.notify("Failed to source " .. expanded .. ": " .. err, vim.log.levels.WARN)
		end
	end
end

local function source_lua_dir(path)
	local expanded = fn.expand(path)
	if fn.isdirectory(expanded) == 1 then
		for _, file in ipairs(fn.glob(expanded .. "/*.lua", false, true)) do
			source_lua_file(file)
		end
	end
end

-- Sensible defaults
require("settings")

-- Plugin manager and plugin specs
require("plugins")

-- Key mappings
require("keymappings")

-- Shared config modules
safe_require("config")

-- Machine-local overrides; never automatically promoted.
source_lua_file("~/.config/nvim/local.lua")

-- Promotion candidates managed by configctl.
source_lua_dir("~/.config/nvim/custom")

-- Adopted fragments preserved during migration.
source_lua_dir("~/.config/nvim/adopted")
