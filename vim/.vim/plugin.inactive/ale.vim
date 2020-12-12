if has_key(plugs, 'ale')
  let g:airline#extensions#ale#enabled = 1

  let g:ale_linter_aliases = {'jsx': ['css', 'javascript']}
  let g:ale_linters = {'jsx': ['stylelint', 'eslint'], 'python': ['pylint']}
  let g:ale_lint_on_text_changed = 'never'

  let g:ale_fixers = {'javascript': ['eslint'], 'python': ['autopep8']}

  let g:ale_fix_on_save = 1

elseif !g:isSlim
  echom "ale plugin not installed"
endif