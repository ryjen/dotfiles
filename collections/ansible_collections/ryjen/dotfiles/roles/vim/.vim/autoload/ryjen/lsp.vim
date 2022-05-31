
function! ryjen#lsp#rust()
if executable('rls')
  au User lsp_setup call lsp#register_server({
        \ 'name': 'rls',
        \ 'cmd': {server_info->['rustup', 'run', 'nightly', 'rls']},
        \ 'whitelist': ['rust'],
        \ })
else
  echom "rls not available for rust lsp"
endif
endfunction

function! ryjen#lsp#go()
if executable('go-langserver')
  au User lsp_setup call lsp#register_server({
        \ 'name': 'go-langserver',
        \ 'cmd': {server_info->['go-langserver', '-mode', 'stdio']},
        \ 'whitelist': ['go'],
        \ })
else
  echom "go-langserver not available for lsp"
endif
endfunction

function! ryjen#lsp#cpp()
if executable('cquery')
  au User lsp_setup call lsp#register_server({
        \ 'name': 'cquery',
        \ 'cmd': {server_info->['cquery']},
        \ 'root_uri': {server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'compile_commands.json'))},
        \ 'initialization_options': { 'cacheDirectory': '/path/to/cquery/cache' },
        \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp', 'cc'],
        \ })
else
  echom "cquery is not available for cpp lsp"
endif
endfunction

function! ryjen#lsp#js()
if executable('javascript-typescript-langserver')
  au User lsp_setup call lsp#register_server({
       \ 'name': 'javascript-typescript-langserver',
       \ 'cmd': {sever_info->['javascript-typescript-langserver']},
       \ 'root_uri': {server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'tsconfig.json'))},
       \ 'whitelist': ['ts', 'tsx', 'js', 'jsx'],
       \ })
else
  echom "javascript-typescript-langserver is not available for lsp"
endif
endfunction

function! ryjen#lsp#ruby()
if executable('solargraph')
    " gem install solargraph
    au User lsp_setup call lsp#register_server({
        \ 'name': 'solargraph',
        \ 'cmd': {server_info->[&shell, &shellcmdflag, 'solargraph stdio']},
        \ 'initialization_options': {"diagnostics": "true"},
        \ 'whitelist': ['ruby'],
        \ })
else
  echom "solargraph is not available for ruby lsp"
endif
endfunction

function! ryjen#lsp#css()
if executable('css-languageserver')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'css-languageserver',
        \ 'cmd': {server_info->[&shell, &shellcmdflag, 'css-languageserver --stdio']},
        \ 'whitelist': ['css', 'less', 'sass'],
        \ })
else
  echom "css-languageserver is not available for lsp"
endif
endfunction

