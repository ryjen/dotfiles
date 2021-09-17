local utils = require('utils')

utils.map('i', '<Tab><Tab>', '<Esc>')
utils.map('v', '<Tab><Tab>', '<Esc>gV')
utils.map('o', '<Tab><Tab>', '<Esc>')
utils.map('n', '<Tab><Tab>', '<C-I>')

--- faster navigation with CTRL
utils.map('n', '<C-h>', '5h')
utils.map('n', '<C-n>', '5j')
utils.map('n', '<C-e>', '5k')
utils.map('n', '<C-i>', '5l')

utils.map('v', '<C-h>', '5h')
utils.map('v', '<C-n>', '5j')
utils.map('v', '<C-e>', '5k')
utils.map('v', '<C-i>', '5l')

--- faster navigation is normal navigation in insert mode
utils.map('i', '<C-h>', '<Left>')
utils.map('i', '<C-n>', '<Down>')
utils.map('i', '<C-e>', '<Up>')
utils.map('i', '<C-i>', '<Right>')

utils.map('n', '<leader>t', ':NvimTreeToggle<CR>')

--- start spell checker
utils.map('n', '<C-P>', ':set spell spelllang=en_ca<CR>')
utils.map('n', '<leader>zP', ':set spell spelllang=en_ca<CR>')
utils.map('n', '<leader>zp', 'z=')
utils.map('n', '<leader>zg', 'zg')
utils.map('n', '<leader>zw', 'zw')

utils.map('n', '<leader>k', ':bp<CR>')
utils.map('n', '<leader>m', ':bn<CR>')
utils.map('n', '<leader>K', ':tabp<CR>')
utils.map('n', '<leader>M', ':tabn<CR>')
utils.map('n', '<leader>x', ':bd<CR>')
utils.map('n', '<leader>X', ':tabclose<CR>')
