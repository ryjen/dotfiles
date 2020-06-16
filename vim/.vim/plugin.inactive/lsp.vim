if has_key(plugs, 'vim-lsp') 
  call ryjen#lsp#rust()
  call ryjen#lsp#go()
  call ryjen#lsp#cpp()
  call ryjen#lsp#ruby()
  call ryjen#lsp#css()
  call ryjen#lsp#js()
else
  echom "lsp plugin not installed"
endif