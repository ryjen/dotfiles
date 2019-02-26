" Fix for colemak.vim keymap collision. tpope/vim-fugitive's maps y<C-G>
" and colemak.vim maps 'y' to 'w' (word). In combination this stalls 'y'
" because Vim must wait to see if the user wants to press <C-G> as well.
augroup RemoveFugitiveMappingForColemak
  autocmd!
  autocmd BufEnter * silent! execute "nunmap <buffer> <silent> y<C-G>"
augroup END

inoremap zz <Esc>

