

if !exists('g:isSlim')
  if -1 != index(["micrantha.com", "labratory"], hostname())
    let g:isSlim = 1
  else
    let g:isSlim = 0
  endif
endif

call plug#begin('~/.local/share/vim/plugged')

" Sensible defaults
Plug 'tpope/vim-sensible'

" Align
Plug 'junegunn/vim-easy-align'

" solarized color scheme
Plug 'altercation/vim-colors-solarized'

" multi-cursor edits
Plug 'terryma/vim-multiple-cursors'

" change surrounding tags on text (cs)
Plug 'tpope/vim-surround'

" a list of tags in file
Plug 'majutsushi/tagbar'

if !g:isSlim

  " Fast fuzzy search
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  " Defaults for fzf search
  Plug 'junegunn/fzf.vim'

  " distraction free writing
  Plug 'junegunn/goyo.vim'

  " extra focus by limiting syntax highlighting
  Plug 'junegunn/limelight.vim'

  " golang tools
  Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

  " dart syntax
  Plug 'dart-lang/dart-vim-plugin'

  " a list of buffers
  Plug 'jeetsukumaran/vim-buffergator'

  " Markdown extras and syntax
  Plug 'godlygeek/tabular'
  Plug 'gabrielelana/vim-markdown'

  " JS syntax
  Plug 'pangloss/vim-javascript'

  " React JSX Syntax
  Plug 'mxw/vim-jsx'

  " rust support
  Plug 'rust-lang/rust.vim'

  " async job api
  Plug 'prabirshrestha/async.vim'

  " language server support
  Plug 'prabirshrestha/vim-lsp'
  Plug 'mattn/vim-lsp-settings'

  " autocompletion
  Plug 'prabirshrestha/asyncomplete.vim'
  Plug 'prabirshrestha/asyncomplete-lsp.vim'

  " confgure lsp for python
  Plug 'ryanolsonx/vim-lsp-python'

  " status line
  Plug 'itchyny/lightline.vim'

  " Lint engine for LSP
  " Plug 'dense-analysis/ale'

endif


call plug#end()

autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif