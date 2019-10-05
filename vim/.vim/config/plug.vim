
call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'

Plug 'junegunn/vim-easy-align'

Plug 'wincent/command-t', { 'do': 'cd ruby/command-t/ext/command-t && ruby extconf.rb && make' }

Plug 'junegunn/vim-emoji'

Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'

Plug 'Chiel92/vim-autoformat'

Plug 'junegunn/goyo.vim'

Plug 'junegunn/limelight.vim'

Plug 'altercation/vim-colors-solarized'

Plug 'fatih/vim-go'

Plug 'terryma/vim-multiple-cursors'

Plug 'jeetsukumaran/vim-buffergator'

Plug 'rust-lang/rust.vim'

Plug 'prabirshrestha/async.vim'

Plug 'prabirshrestha/vim-lsp'

Plug 'racer-rust/vim-racer'

Plug 'itchyny/lightline.vim'

Plug 'tyrannicaltoucan/vim-deep-space'

Plug 'christoomey/vim-tmux-navigator'

Plug 'tpope/vim-obsession'

Plug 'tpope/vim-unimpaired'

Plug 'tpope/vim-fugitive'

Plug 'tpope/vim-surround'

Plug 'airblade/vim-gitgutter'

Plug 'majutsushi/tagbar'

Plug 'edkolev/tmuxline.vim'

Plug 'pangloss/vim-javascript'

Plug 'mxw/vim-jsx'

Plug 'mattn/emmet-vim'

Plug 'w0rp/ale'

Plug 'jooize/vim-colemak'

Plug 'stanangeloff/php.vim'

call plug#end()

autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif
