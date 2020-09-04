if has("nvim")
  " Make escape work in the Neovim terminal.
  tnoremap <Esc> <C-\><C-n>

  " I like relative numbering when in normal mode.
  autocmd TermOpen * setlocal conceallevel=0 colorcolumn=0 relativenumber

  " Prefer Neovim terminal insert mode to normal mode.
  autocmd BufEnter term://* startinsert
else
  echom "using regular vim, consider using nvim"
endif

" cursor line colour
hi CursorLine cterm=NONE ctermbg=darkgreen ctermfg=white guibg=darkgreen guifg=white

