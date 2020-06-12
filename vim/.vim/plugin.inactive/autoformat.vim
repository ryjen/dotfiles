if has_key(plugs, 'autoformat')
  let g:autoformat_autoindent = 0
  let g:autoformat_retab = 0

  au BufWrite * :Autoformat

  noremap <leader>f :Autoformat<CR>
else
  echom "autoformat plugin not installed"
endif