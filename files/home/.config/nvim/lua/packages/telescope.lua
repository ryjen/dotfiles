local utils = require ("utils")

utils.map('n', '<Leader>.', '<Cmd>Telescope git_files<CR>')
utils.map('n', '<Leader>b', ':Telescope find_buffers<CR>')
utils.map('n', '<Leader>f', ':Telescope file_browser<CR>')
utils.map('n', '<Leader>t', ':Telescope find_tags<CR>')
