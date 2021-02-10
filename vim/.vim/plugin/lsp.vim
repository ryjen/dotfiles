let g:lsp_settings = {
    \ 'analysis-server-dart-snapshot': {
    \     'cmd': [
    \         '/opt/dart-sdk/bin/dart',
    \         '/opt/dart-sdk/bin/bin/snapshots/analysis_server.dart.snapshot',
    \         '--lsp'
    \     ],
    \ },
\ }
nnoremap ld :LspDefinition<CR>
nnoremap lh :LspHover<CR>
nnoremap lf :LspDocumentFormat<CR>
nnoremap lr :LspReferences<CR>
nnoremap ln :LspRename<CR>

" handle hover tabbing
inoremap <S-Tab> <Down>