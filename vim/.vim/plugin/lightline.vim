if has_key(plugs, 'lightline.vim')
  " lightline {{{
  let g:lightline = {}
  let g:lightline.colorscheme = 'solarized'
  let g:lightline.active = {
      \     'left': [['mode', 'paste'], ['fugitive'], ['filename_active']],
      \     'right': [['lineinfo', 'error', 'warning'], ['fileinfo'], ['filetype']]
      \ }
  let g:lightline.inactive = {
      \     'left': [['filename_inactive']],
      \     'right': [['lineinfo'], ['fileinfo'], ['filetype']]
      \ }
  let g:lightline.component_function = {
      \     'mode': 'ryjen#lightline#Mode',
      \     'fugitive': 'LightlineFugitive',
      \     'filename_active': 'ryjen#lightline#FilenameActive',
      \     'filename_inactive': 'ryjen#lightline#FilenameInactive',
      \     'lineinfo': 'ryjen#lightline#Lineinfo',
      \     'fileinfo': 'ryjen#lightline#Fileinfo',
      \     'filetype': 'ryjen#lightline#Filetype'
      \ }
  let g:lightline.component_expand = {
      \     'error': 'LightlineErrors',
      \     'warning': 'LightlineWarnings',
      \ }
  let g:lightline.component_type = {
      \     'error': 'error',
      \     'warning': 'warning'
      \ }
  let g:lightline.separator = { 'left': '', 'right': '' }
  let g:lightline.subseparator = { 'left': '', 'right': '' }

  try
      let s:palette = g:lightline#colorscheme#{g:lightline.colorscheme}#palette

      call add(s:palette.normal.left[0], 'bold')
      call add(s:palette.insert.left[0], 'bold')
      call add(s:palette.visual.left[0], 'bold')
      call add(s:palette.replace.left[0], 'bold')
  catch
  endtry

  au BufEnter,CursorHold * if ryjen#lightline#ShouldRefresh() | call lightline#update() | endif
  " }}}
elseif !g:isSlim
  echom "lightline plugin not installed"
endif
