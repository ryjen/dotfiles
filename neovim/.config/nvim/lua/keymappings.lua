local utils = require('utils')

utils.map('i', '<Tab><Tab>', '<Esc>')
utils.map('v', '<Tab><Tab>', '<Esc>gV')
utils.map('o', '<Tab><Tab>', '<Esc>')
utils.map('n', '<Tab><Tab>', '<C-I>')

utils.map('n', '<C-h>', '5h')
utils.map('n', '<C-n>', '5j')
utils.map('n', '<C-e>', '5k')
utils.map('n', '<C-i>', '5l')

--- start spell checker
utils.map('n', '<C-P>', ':set spell spelllang=en_ca<CR>')
utils.map('n', '<leader>P', ':set spell spelllang=en_ca<CR>')
utils.map('n', '<leader>p', 'z=')
utils.map('n', '<leader>g', 'zg')

utils.map('n', '<leader>k', ':bp<CR>')
utils.map('n', '<leader>m', ':bn<CR>')
utils.map('n', '<leader>K', ':tabp<CR>')
utils.map('n', '<leader>M', ':tabn<CR>')
utils.map('n', '<leader>x', ':bd<CR>')
utils.map('n', '<leader>X', ':tabclose<CR>')
