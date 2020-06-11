
call plug#begin('~/.local/share/vim/plugged')

" Sensible defaults
Plug 'tpope/vim-sensible'

" Align
Plug 'junegunn/vim-easy-align'

" Fast fuzzy search
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
" Defaults for fzf search
Plug 'junegunn/fzf.vim'

" Formatting
Plug 'Chiel92/vim-autoformat'

" distraction free writing
Plug 'junegunn/goyo.vim'

" extra focus by limiting syntax highlighting
Plug 'junegunn/limelight.vim'

" solarized color scheme
Plug 'altercation/vim-colors-solarized'

" golang tools
Plug 'fatih/vim-go'

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

" Colemake remapping
Plug 'jooize/vim-colemak'

call plug#end()

autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif
