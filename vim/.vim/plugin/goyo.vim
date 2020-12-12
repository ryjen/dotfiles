if has_key(plugs, 'goyo.vim')
  let g:goyo_width = '85%'

  nnoremap <Leader>G :Goyo<CR>
  xnoremap <Leader>G :Goto<CR>
elseif !g:isSlim
  echom "goyo plugin not installed"
endif
