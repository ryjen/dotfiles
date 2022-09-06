local utils = require("config.utils")

vim.cmd([[set shortmess+=c]])
vim.g.completion_confirm_key = ""
vim.g.completion_matching_strategy_list = { "exact", "substring", "fuzzy" }

-- <Tab> to navigate the completion menu
utils.opt("completeopt", "menuone,noinsert,noselect")
