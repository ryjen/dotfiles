
call plug#begin('~/.local/share/vim/plugged')

Plug 'tpope/vim-sensible'

Plug 'junegunn/vim-easy-align'

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

Plug 'Chiel92/vim-autoformat'

Plug 'altercation/vim-colors-solarized'

Plug 'terryma/vim-multiple-cursors'

Plug 'jeetsukumaran/vim-buffergator'

Plug 'prabirshrestha/async.vim'

Plug 'christoomey/vim-tmux-navigator'

Plug 'tpope/vim-obsession'

Plug 'tpope/vim-unimpaired'

Plug 'tpope/vim-fugitive'

Plug 'tpope/vim-surround'

Plug 'airblade/vim-gitgutter'

Plug 'majutsushi/tagbar'

Plug 'edkolev/tmuxline.vim'

Plug 'jooize/vim-colemak'

call plug#end()

autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q
  \| endif
