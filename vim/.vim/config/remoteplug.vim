
call plug#begin('~/.local/share/vim/plugged')

" Fast fuzzy search
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
" Defaults for fzf search
Plug 'junegunn/fzf.vim'

" Markdown extras and syntax
Plug 'godlygeek/tabular'
Plug 'gabrielelana/vim-markdown'

" Sensible defaults
Plug 'tpope/vim-sensible'

" Align
Plug 'junegunn/vim-easy-align'

" distraction free writing
Plug 'junegunn/goyo.vim'

" extra focus by limiting syntax highlighting
Plug 'junegunn/limelight.vim'

" solarized color scheme
Plug 'altercation/vim-colors-solarized'

" golang tools
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

" multi-cursor edits
Plug 'terryma/vim-multiple-cursors'

" a list of buffers
Plug 'jeetsukumaran/vim-buffergator'

" rust support
Plug 'rust-lang/rust.vim'

" async job api
Plug 'prabirshrestha/async.vim'

" language server support
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'

Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" status line
Plug 'itchyny/lightline.vim'

" change surrounding tags on text (cs)
Plug 'tpope/vim-surround'

" a list of tags in file
Plug 'majutsushi/tagbar'

" JS syntax
Plug 'pangloss/vim-javascript'

" React JSX Syntax
Plug 'mxw/vim-jsx'

" Lint engine for LSP
Plug 'dense-analysis/ale'


call plug#end()

autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif
