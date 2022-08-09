local utils = require('config.utils')
local opt = utils.opt
local autocmd = utils.autocmd

local g = vim.g
local cmd = vim.cmd
local fn = vim.fn
local indent = 2

g.mapleader = [[ ]]
g.maplocalleader = [[,]]
g.solarized_termtrans = 0

cmd 'syntax enable'
cmd 'filetype plugin indent on'

local buffer = { o, bo }
local window = { o, wo }

opt('background', 'dark')
opt('gdefault', true)
opt('termguicolors', true)
opt('hidden', true)
opt('ignorecase', true)
opt('scrolloff', 4 )
opt('shiftround', true)
opt('smartcase', true)
opt('splitbelow', true)
opt('splitright', true)
opt('wildmode', 'list:longest')
opt('clipboard','unnamed,unnamedplus')
opt('softtabstop', 0)
opt('shiftwidth', indent)
--opt('lcs', 'tab:▸,trail:·,eol:¬,nbsp:_')
opt('hlsearch', true)
opt('incsearch', true)
opt('mouse', 'a')
opt('title', true)
opt('scrolloff', 3)
opt('completeopt', "menuone,noselect")

opt('expandtab', true, buffer)
opt('smartindent', true, buffer)
opt('tabstop', indent, buffer)
opt('shiftwidth', indent, buffer)
opt('tabstop', indent, buffer)
opt('expandtab', true, buffer)
opt('binary', true, buffer)
opt('endofline', false, buffer)

opt('number', true, window)
opt('relativenumber', true, window)
opt('cursorline', true, window)

cmd 'hi CursorLine cterm=NONE ctermbg=darkgreen ctermfg=white guibg=darkgreen guifg=white'

--autocmd('start_screen', [[VimEnter * ++once lua require('start').start()]], true)
autocmd(
  'syntax_aucmds',
  [[Syntax * syn match extTodo "\<\(NOTE\|HACK\|BAD\|TODO\):\?" containedin=.*Comment.* | hi! link extTodo Todo]],
  true
)
autocmd('misc_aucmds', {
  [[BufWinEnter * checktime]],
  [[TextYankPost * silent! lua vim.highlight.on_yank()]],
  [[FileType qf set nobuflisted ]],
}, true)

-- Highlight on yank
--vim.cmd 'au TextYankPost * lua vim.highlight.on_yank {on_visual = false}'
