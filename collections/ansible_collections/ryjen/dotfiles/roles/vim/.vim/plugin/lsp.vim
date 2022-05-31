let g:lsp_settings = {
    \ 'analysis-server-dart-snapshot': {
    \     'cmd': [
    \         '/opt/dart-sdk/bin/dart',
    \         '/opt/dart-sdk/bin/bin/snapshots/analysis_server.dart.snapshot',
    \         '--lsp'
    \     ],
    \ },
\ }

if executable('sourcekit-lsp')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'sourcekit-lsp',
        \ 'cmd': {server_info->['sourcekit-lsp']},
        \ 'whitelist': ['swift'],
        \ })
endif

nnoremap ld :LspDefinition<CR>
nnoremap lh :LspHover<CR>
nnoremap lf :LspDocumentFormat<CR>
nnoremap lr :LspReferences<CR>
nnoremap ln :LspRename<CR>

" handle hover tabbing
inoremap <S-Tab> <Down>