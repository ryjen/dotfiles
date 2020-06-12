

function! ryjen#lightline#IsLean()
    return &ft =~ 'vimfiler\|tagbar\|gundo\|vim-plug'
endfunction

function! ryjen#lightline#Mode()
    return ryjen#lightline#IsLean() ? toupper(&ft) : lightline#mode()
endfunction

function! ryjen#lightline#Fugitive()
    if ryjen#lightline#IsLean() || !exists('*fugitive#head')
        return ''
    endif
    let l:branch = fugitive#head()
    return l:branch !=# '' ? ' '.l:branch : ''
endfunction

function! ryjen#lightline#FilenameActive()
    if ryjen#lightline#IsLean()
        return ''
    endif
    return (empty(expand('%:t')) ? '[No Name]' : expand('%:t')) .
        \  (empty(ryjen#lightline#Modified()) ? '' : ryjen#lightline#Modified()) .
        \  (empty(ryjen#lightline#Readonly()) ? '' : ' '.ryjen#lightline#Readonly())
endfunction

function! ryjen#lightline#FilenameInactive()
    return ryjen#lightline#IsLean() ? toupper(&ft) : ryjen#lightline#FilenameActive()
endfunction

function! ryjen#lightline#Modified()
    return &modifiable && &modified ? '[+]' : ''
endfunction

function! ryjen#lightline#Readonly()
    return &readonly ? '' : ''
endfunction

function! ryjen#lightline#Lineinfo()
    if &ft =~ 'vimfiler'
        return '🖿 '
    elseif &ft =~ 'vim-plug'
        return '⚉ '
    elseif &ft =~ 'tagbar'
        return '🖜 '
    elseif ryjen#lightline#IsLean()
        return ' '
    endif
    return printf('%d%% ☰  %d/%d:%d ', 100*line('.')/line('$'), line('.'), line('$'), col('.'))
endfunction

function! ryjen#lightline#Fileinfo()
    return ryjen#lightline#IsLean() ? '' : printf('%s[%s]', empty(&fenc)?&enc:&fenc, &ff)
endfunction

function! ryjen#lightline#Filetype()
    return ryjen#lightline#IsLean() ? '' : &ft
endfunction

function! ryjen#lightline#Errors()
    let g:syntastic_stl_format = '%E{%fe   %e ✘}'
    let l:ycm_error_count = youcompleteme#GetErrorCount()
    return l:ycm_error_count > 0 ? printf('%d ✘', l:ycm_error_count) : SyntasticStatuslineFlag()
endfunction

function! ryjen#lightline#Warnings()
    let g:syntastic_stl_format = '%W{%fw   %w ☢}'
    let l:ycm_warning_count = youcompleteme#GetWarningCount()
    return l:ycm_warning_count > 0 ? printf('%d ☢', l:ycm_warning_count) : SyntasticStatuslineFlag()
endfunction

function! ryjen#lightline#ShouldRefresh()
    if empty(&ft) || !exists('#ryjen#lightline#')
        return 0
    elseif ryjen#lightline#IsLean()
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
    let s:palette = g:ryjen#lightline##colorscheme#{g:lightline.colorscheme}#palette

    call add(s:palette.normal.left[0], 'bold')
    call add(s:palette.insert.left[0], 'bold')
    call add(s:palette.visual.left[0], 'bold')
    call add(s:palette.replace.left[0], 'bold')
catch
endtry

au BufEnter,CursorHold * if ryjen#lightline#ShouldRefresh() | call lightline#update() | endif
" }}}
