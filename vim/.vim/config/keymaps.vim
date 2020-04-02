
noremap <leader>ss :call StripWhitespace()<CR>

" Save a file as root (,W)
noremap <leader>W :w !sudo tee % > /dev/null<CR>

" Temporarily remove dependency on arrow key to encourage other navigation
noremap <Up> <nop>
noremap <Down> <nop>
noremap <Left> <nop>
noremap <Right> <nop>

" easy escape key
nnoremap <leader><leader> <Esc>
vnoremap <leader><leader> <Esc>gV
onoremap <leader><leader> <Esc>
cnoremap <leader><leader> <C-C><Esc>
inoremap <leader><leader> <Esc>`^

" start spell checker
noremap <C-P> :set spell spelllang=en_ca<CR>
noremap <leader>p :set spell spelllang=en_ca<CR>

noremap <leader>k :bn<CR>

" for vimdiff
if &diff
    noremap <space>   ]cz.
    noremap <S-space> [cz.
    noremap <leader>R  :diffg RE<CR>
    noremap <leader>B  :diffg BA<CR>
    noremap <leader>L  :diffg LO<CR>
endif

