local utils = require('utils')

local cmd = vim.cmd
local fn = vim.fn
local indent = 2

vim.g.mapleader = ','

cmd 'syntax enable'
cmd 'filetype plugin indent on'

--- theme
utils.opt('o', 'background', 'dark')
vim.g.solarized_termtrans = 1

utils.opt('o', 'gdefault', true)
utils.opt('o', 'termguicolors', true)
utils.opt('b', 'expandtab', true)
utils.opt('b', 'shiftwidth', indent)
utils.opt('b', 'smartindent', true)
utils.opt('b', 'tabstop', indent)
utils.opt('o', 'hidden', true)
utils.opt('o', 'ignorecase', true)
utils.opt('o', 'scrolloff', 4 )
utils.opt('o', 'shiftround', true)
utils.opt('o', 'smartcase', true)
utils.opt('o', 'splitbelow', true)
utils.opt('o', 'splitright', true)
utils.opt('o', 'wildmode', 'list:longest')
utils.opt('w', 'number', true)
utils.opt('w', 'relativenumber', true)
utils.opt('o', 'clipboard','unnamed,unnamedplus')
utils.opt('b', 'binary', true)
utils.opt('b', 'endofline', false)
utils.opt('w', 'cursorline', true)
utils.opt('b', 'tabstop', indent)
utils.opt('b', 'expandtab', true)
utils.opt('o', 'softtabstop', 0)
utils.opt('o', 'shiftwidth', indent)
--utils.opt('o', 'lcs', 'tab:▸,trail:·,eol:¬,nbsp:_')
utils.opt('o', 'hlsearch', true)
utils.opt('o', 'incsearch', true)
utils.opt('o', 'mouse', 'a')
utils.opt('o', 'title', true)
utils.opt('o', 'scrolloff', 3)
utils.opt('o', 'completeopt', "menuone,noselect")

cmd 'hi CursorLine cterm=NONE ctermbg=darkgreen ctermfg=white guibg=darkgreen guifg=white'

-- Highlight on yank
vim.cmd 'au TextYankPost * lua vim.highlight.on_yank {on_visual = false}'
