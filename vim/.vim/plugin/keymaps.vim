

noremap <leader>ss :call ryjen#misc#StripWhitespace()<CR>

set listchars=tab:»\ ,extends:›,precedes:‹,nbsp:·,trail:·
autocmd FileWritePre * call ryjen#misc#StripWhitespace()
autocmd FileAppendPre * call ryjen#misc#StripWhitespace()
autocmd FilterWritePre * call ryjen#misc#StripWhitespace()
autocmd BufWritePre * call ryjen#misc#StripWhitespace()

" Save a file as root (,W)
noremap <leader>W :w !sudo tee % > /dev/null<CR>

" Temporarily remove dependency on arrow key to encourage other navigation
noremap <Up> <nop>
noremap <Down> <nop>
noremap <Left> <nop>
noremap <Right> <nop>

" start spell checker
noremap <C-P> :set spell spelllang=en_ca<CR>
noremap <leader>P :set spell spelllang=en_ca<CR>
noremap <leader>p z=
noremap <leader>g zg

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
