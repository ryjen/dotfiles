
noremap <leader>ss :call StripWhitespace()<CR>

" Save a file as root (,W)
noremap <leader>W :w !sudo tee % > /dev/null<CR>

" Temporarily remove dependency on arrow key to encourage other navigation
noremap <Up> <nop>
noremap <Down> <nop>
noremap <Left> <nop>
noremap <Right> <nop>

" easy escape key
nnoremap <leader>. <Esc>
vnoremap <leader>. <Esc>gV
onoremap <leader>. <Esc>
cnoremap <leader>. <C-C><Esc>
inoremap <leader>. <Esc>`^

" start spell checker
noremap <C-P> :set spell spelllang=en_ca<CR>
noremap <leader>p :set spell spelllang=en_ca<CR>

noremap <leader>k :bn<CR>
