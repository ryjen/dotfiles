
" Strip trailing whitespace (,ss)
function! ryjen#misc#StripWhitespace()
  if exists('b:NoStripWhitespace')
    return
  endif
	let save_cursor = getpos(".")
	let old_query = getreg('/')
	:%s/\s\+$//e
	call setpos('.', save_cursor)
	call setreg('/', old_query)
endfunction
