
noremap <leader>ss :call misc#StripWhitespace()<CR>

" Save a file as root (,W)
noremap <leader>W :w !sudo tee % > /dev/null<CR>

" Temporarily remove dependency on arrow key to encourage other navigation
noremap <Up> <nop>
noremap <Down> <nop>
noremap <Left> <nop>
noremap <Right> <nop>

" easy escape key
"nnoremap <Tab><Tab> <Esc>
"vnoremap <Tab><Tab> <Esc>gV
"onoremap <Tab><Tab> <Esc>
"cnoremap <Tab><Tab> <C-C><Esc>
"inoremap <Tab><Tab> <Esc>`^

" start spell checker
noremap <leader>P :set spell spelllang=en_ca<CR>
noremap <leader>p ]s<CR>
noremap <leader>z z=<CR>

noremap <leader>k :bp<CR>
noremap <leader>m :bn<CR>
noremap <leader>K :tabp<CR>
noremap <leader>M :tabn<CR>
noremap <leader>x :bd<CR>
noremap <leader>X :tabclose<CR>

" for vimdiff
if &diff
    noremap <space>   ]cz.
    noremap <S-space> [cz.
    noremap <leader>R  :diffg RE<CR>
    noremap <leader>B  :diffg BA<CR>
    noremap <leader>L  :diffg LO<CR>
endif
