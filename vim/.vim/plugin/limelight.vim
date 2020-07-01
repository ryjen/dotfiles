if has_key(plugs, 'limelight.vim')
  " Color name (:help cterm-colors) or ANSI code
  let g:limelight_conceal_ctermfg = 'gray'
  "let g:limelight_conceal_ctermfg = 240

  " Color name (:help gui-colors) or RGB color
  let g:limelight_conceal_guifg = '#555555'

  " Default: 0.5
  "let g:limelight_default_coefficient = 0.9

  " Number of preceding/following paragraphs to include (default: 0)
  let g:limelight_paragraph_span = 1

  " Beginning/end of paragraph
  "   When there's no empty line between the paragraphs
  "   and each paragraph starts with indentation
  "let g:limelight_bop = '^\s'
  "let g:limelight_eop = '\ze\n^\s'

  " Highlighting priority (default: 10)
  "   Set it to -1 not to overrule hlsearch
  "let g:limelight_priority = -1

  nnoremap <Leader>l <Plug>(Limelight)
  xnoremap <Leader>l <Plug>(Limelight)

  autocmd! User GoyoEnter Limelight
  autocmd! User GoyoLeave Limelight!
elseif !g:isSlim
  echom "limelight plugin not installed"
endif