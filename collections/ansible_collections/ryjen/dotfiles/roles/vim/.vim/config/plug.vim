
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

" solarized color scheme
Plug 'altercation/vim-colors-solarized'

" multi-cursor edits
Plug 'terryma/vim-multiple-cursors'

if !g:isSlim
  " a list of tags in file
  Plug 'majutsushi/tagbar'

  " Fast fuzzy search
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }

  " Defaults for fzf search
  Plug 'junegunn/fzf.vim'

  " distraction free writing
  Plug 'junegunn/goyo.vim'

  " extra focus by limiting syntax highlighting
  Plug 'junegunn/limelight.vim'

  " a list of buffers
  Plug 'jeetsukumaran/vim-buffergator'

  " async job api
  Plug 'prabirshrestha/async.vim'

  if has('nvim-0.5.0')
    " better syntax highlighting
    Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
    "  Plug 'nvim-treesitter/playground'
    "
    " TODO: replace language syntax plugins
  endif

  "if has('nvim-0.5')
    " language server support
    " Plug 'neovim/nvim-lspconfig'
    " Plug 'kabouzeid/nvim-lspinstall'

    " autocompletion
    " Plug 'hrsh7th/nvim-compe'

    " dependencies
    " Plug 'nvim-lua/popup.nvim'
    " Plug 'nvim-lua/plenary.nvim'

    " telescope
    " Plug 'nvim-telescope/telescope.nvim'

  "else
    " language server support
    Plug 'prabirshrestha/vim-lsp'
    Plug 'mattn/vim-lsp-settings'

    " autocompletion
    Plug 'prabirshrestha/asyncomplete.vim'
    Plug 'prabirshrestha/asyncomplete-lsp.vim'

    " confgure lsp for python
    " Plug 'ryanolsonx/vim-lsp-python'

    " Lint engine for LSP
    Plug 'dense-analysis/ale'
    Plug 'rhysd/vim-lsp-ale'
  "endif


  " status line
  Plug 'itchyny/lightline.vim'


  "
  " LANGUAGE SUPPORT
  "

  " swift lang
  Plug 'keith/swift.vim'

  " elixir
  Plug 'elixir-editors/vim-elixir'

  " Flutter
  Plug 'nvim-lua/plenary.nvim'
  Plug 'akinsho/flutter-tools.nvim'

  " Markdown extras and syntax
  Plug 'godlygeek/tabular'
  Plug 'gabrielelana/vim-markdown'

  " JS syntax
  Plug 'pangloss/vim-javascript'

  " Typescript
  Plug 'leafgarland/typescript-vim'
  Plug 'styled-components/vim-styled-components', { 'branch': 'main' }

  " React JSX Syntax
  Plug 'mxw/vim-jsx'
  Plug 'peitalin/vim-jsx-typescript'

  " rust support
  Plug 'rust-lang/rust.vim'

  " golang tools
  Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

  " dart syntax
  Plug 'dart-lang/dart-vim-plugin'

endif

"
" UNUSED
"

" Align
"Plug 'junegunn/vim-easy-align'

" change surrounding tags on text (cs)
"Plug 'tpope/vim-surround'


call plug#end()

autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif