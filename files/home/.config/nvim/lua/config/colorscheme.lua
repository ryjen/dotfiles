local utils = require("config.utils")
utils.opt("termguicolors", true)

local ok, err = pcall(vim.cmd.colorscheme, "solarized")
if not ok then
	vim.notify("solarized colorscheme unavailable: " .. err, vim.log.levels.WARN)
end
