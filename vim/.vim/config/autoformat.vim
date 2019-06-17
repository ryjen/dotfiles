let g:autoformat_autoindent = 0
let g:autoformat_retab = 0

au BufWrite * :Autoformat

noremap <leader>f :Autoformat<CR>

