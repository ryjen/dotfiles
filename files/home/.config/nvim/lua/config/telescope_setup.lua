local map = require('config.utils').map

local silent = { silent = true }
-- Navigate buffers and repos
map('n', '<c-b>', [[<cmd>Telescope buffers show_all_buffers=true theme=get_dropdown<cr>]], silent)
map('n', '<c-c>', [[<cmd>Telescope frecency theme=get_dropdown<cr>]], silent)
map('n', '<c-s>', [[<cmd>Telescope git_files theme=get_dropdown<cr>]], silent)
map('n', '<c-d>', [[<cmd>Telescope find_files theme=get_dropdown<cr>]], silent)
map('n', '<c-g>', [[<cmd>Telescope live_grep theme=get_dropdown<cr>]], silent)

map('n', '<space><space>', [[<cmd>Telescope git_files theme=get_dropdown<cr>]], silent)
