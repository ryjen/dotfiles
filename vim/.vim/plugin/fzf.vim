if has_key(plugs, 'fzf.vim')

  nmap <Leader>. :Files<CR>
  nmap <Leader>? :Buffers<CR>

  nmap <Leader>' :Tags<CR>

  " Mapping selecting mappings
  nmap <leader><tab> <plug>(fzf-maps-n)
  xmap <leader><tab> <plug>(fzf-maps-x)
  omap <leader><tab> <plug>(fzf-maps-o)

  " Insert mode completion
  imap <c-f><c-n> <plug>(fzf-complete-word)
  imap <c-f><c-e> <plug>(fzf-complete-path)
  imap <c-f><c-i> <plug>(fzf-complete-file-ag)
  imap <c-f><c-o> <plug>(fzf-complete-line)

  " Advanced customization using Vim function
  inoremap <expr> <c-x><c-k> fzf#vim#complete#word({'left': '15%'})

elseif !g:isSlim
  echom "fzf plugin not installed"
endif