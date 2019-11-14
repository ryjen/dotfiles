
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
    \     'mode': 'LightlineMode',
    \     'fugitive': 'LightlineFugitive',
    \     'filename_active': 'LightlineFilenameActive',
    \     'filename_inactive': 'LightlineFilenameInactive',
    \     'lineinfo': 'LightlineLineinfo',
    \     'fileinfo': 'LightlineFileinfo',
    \     'filetype': 'LightlineFiletype'
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

function! LightlineIsLean()
    return &ft =~ 'vimfiler\|tagbar\|gundo\|vim-plug'
endfunction

function! LightlineMode()
    return LightlineIsLean() ? toupper(&ft) : lightline#mode()
endfunction

function! LightlineFugitive()
    if LightlineIsLean() || !exists('*fugitive#head')
        return ''
    endif
    let l:branch = fugitive#head()
    return l:branch !=# '' ? ' '.l:branch : ''
endfunction

function! LightlineFilenameActive()
    if LightlineIsLean()
        return ''
    endif
    return (empty(expand('%:t')) ? '[No Name]' : expand('%:t')) .
        \  (empty(LightlineModified()) ? '' : LightlineModified()) .
        \  (empty(LightlineReadonly()) ? '' : ' '.LightlineReadonly())
endfunction

function! LightlineFilenameInactive()
    return LightlineIsLean() ? toupper(&ft) : LightlineFilenameActive()
endfunction

function! LightlineModified()
    return &modifiable && &modified ? '[+]' : ''
endfunction

function! LightlineReadonly()
    return &readonly ? '' : ''
endfunction

function! LightlineLineinfo()
    if &ft =~ 'vimfiler'
        return '🖿 '
    elseif &ft =~ 'vim-plug'
        return '⚉ '
    elseif &ft =~ 'tagbar'
        return '🖜 '
    elseif LightlineIsLean()
        return ' '
    endif
    return printf('%d%% ☰  %d/%d:%d ', 100*line('.')/line('$'), line('.'), line('$'), col('.'))
endfunction

function! LightlineFileinfo()
    return LightlineIsLean() ? '' : printf('%s[%s]', empty(&fenc)?&enc:&fenc, &ff)
endfunction

function! LightlineFiletype()
    return LightlineIsLean() ? '' : &ft
endfunction

function! LightlineErrors()
    let g:syntastic_stl_format = '%E{%fe   %e ✘}'
    let l:ycm_error_count = youcompleteme#GetErrorCount()
    return l:ycm_error_count > 0 ? printf('%d ✘', l:ycm_error_count) : SyntasticStatuslineFlag()
endfunction

function! LightlineWarnings()
    let g:syntastic_stl_format = '%W{%fw   %w ☢}'
    let l:ycm_warning_count = youcompleteme#GetWarningCount()
    return l:ycm_warning_count > 0 ? printf('%d ☢', l:ycm_warning_count) : SyntasticStatuslineFlag()
endfunction

function! LightlineShouldRefresh()
    if empty(&ft) || !exists('#lightline')
        return 0
    elseif LightlineIsLean()
        return 1
    elseif !exists('#youcompleteme')
        return 0
    endif

    let l:result = 0

    let l:ycm_warning_count = youcompleteme#GetWarningCount()
    if exists('b:last_ycm_warning_count')
        if b:last_ycm_warning_count != l:ycm_warning_count
            let l:result = 1
        endif
    endif
    let b:last_ycm_warning_count = l:ycm_warning_count

    let l:ycm_error_count = youcompleteme#GetErrorCount()
    if exists('b:last_ycm_error_count')
        if b:last_ycm_error_count != l:ycm_error_count
            let l:result = 1
        endif
    endif
    let b:last_ycm_error_count = l:ycm_error_count

    return l:result
endfunction

try
    let s:palette = g:lightline#colorscheme#{g:lightline.colorscheme}#palette

    call add(s:palette.normal.left[0], 'bold')
    call add(s:palette.insert.left[0], 'bold')
    call add(s:palette.visual.left[0], 'bold')
    call add(s:palette.replace.left[0], 'bold')
catch
endtry

au BufEnter,CursorHold * if LightlineShouldRefresh() | call lightline#update() | endif
" }}}
