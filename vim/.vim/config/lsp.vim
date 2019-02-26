
if executable('rls')
  au User lsp_setup call lsp#register_server({
        \ 'name': 'rls',
        \ 'cmd': {server_info->['rustup', 'run', 'nightly', 'rls']},
        \ 'whitelist': ['rust'],
        \ })
endif
if executable('go-langserver')
  au User lsp_setup call lsp#register_server({
        \ 'name': 'go-langserver',
        \ 'cmd': {server_info->['go-langserver', '-mode', 'stdio']},
        \ 'whitelist': ['go'],
        \ })
endif
if executable('cquery')
  au User lsp_setup call lsp#register_server({
        \ 'name': 'cquery',
        \ 'cmd': {server_info->['cquery']},
        \ 'root_uri': {server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'compile_commands.json'))},
        \ 'initialization_options': { 'cacheDirectory': '/path/to/cquery/cache' },
        \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp', 'cc'],
        \ })
endif
if executable('javascript-typescript-langserver')
  au User lsp_setup call lsp#register_server({
       \ 'name': 'javascript-typescript-langserver',
       \ 'cmd': {sever_info->['javascript-typescript-langserver']},
       \ 'root_uri': {server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'tsconfig.json'))},
       \ 'whitelist': ['ts', 'tsx', 'js', 'jsx'],
       \ })
endif

noremap <silent> H :call LspHover()<CR>
noremap <silent> Z :call LspDefinition()<CR>
noremap <silent> R :call LspRename()<CR>
noremap <silent> S :call LspDocumentSymbol()<CR>
