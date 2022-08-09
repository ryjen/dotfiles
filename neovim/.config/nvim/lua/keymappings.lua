local utils = require('config.utils')

utils.map('i', '<Tab><Tab>', '<Esc>')
utils.map('v', '<Tab><Tab>', '<Esc>gV')
utils.map('o', '<Tab><Tab>', '<Esc>')
utils.map('n', '<Tab><Tab>', '<C-I>')

--- faster navigation with CTRL
local modes = {'n', 'v'}
utils.map(modes, '<C-h>', '5h')
utils.map(modes, '<C-n>', '5j')
utils.map(modes, '<C-e>', '5k')
utils.map(modes, '<C-i>', '5l')

--- faster navigation is normal navigation in insert mode
utils.map('i', '<C-h>', '<Left>')
utils.map('i', '<C-n>', '<Down>')
utils.map('i', '<C-e>', '<Up>')
utils.map('i', '<C-i>', '<Right>')

--- start spell checker
utils.map('n', '<F3>', ':set spell spelllang=en_ca<CR>')
utils.map('i', '<F3>', '<C-O>:set spell spelllang=en_ca<CR>')

utils.map('n', '<leader>k', ':bp<CR>')
utils.map('n', '<leader>m', ':bn<CR>')
utils.map('n', '<leader>K', ':tabp<CR>')
utils.map('n', '<leader>M', ':tabn<CR>')
utils.map('n', '<leader>x', ':bd<CR>')
utils.map('n', '<leader>X', ':tabclose<CR>')

utils.map('n', '<leader><leader>', '<Cmd>Telescope frecency theme=get_dropdown<CR>')
