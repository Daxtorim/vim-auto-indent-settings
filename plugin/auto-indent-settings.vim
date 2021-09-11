" Name:         auto-indent-settings
" Version:      0.1
" Author:       Daxtorim
" Updates:      http://github.com/Daxtorim/vim-auto-indent-settings
" Purpose:      Detect file indentation settings based on simple heuristics of current buffer

if exists("loaded_auto_indent_settings")
	finish
endif
let loaded_auto_indent_settings = 1

fun! s:IndentAutoIndicator(...)
	" If optional arg exists echo out verbose string, else return short version
	if get(a:, 0, 0)
		let et = ( &expandtab ? 'expandtab' : 'noexpandtab')
		echo 'auto-indent-settings: tabstop='.&tabstop.'; softtabstop='.&softtabstop.'; shiftwidth='.&shiftwidth.'; '.et
	else
		let et = ( &expandtab ? 'et' : 'noet')
		return 'ts='.&tabstop.',sts='.&softtabstop.',sw='.&shiftwidth.','.et
	endif
endfunction

fun! s:WasSetByModeline(opts)
	" adapted from http://vi.stackexchange.com/a/33099
	return map(a:opts, { _, val -> split(execute(printf('verbose setlocal %s?', val)), '\n', 1)[-1] =~# 'Last set from modeline line \d\+'})
endfun

fun! s:IndentAutoDetect()
	let has_leading_tabs = 0
	let has_leading_spaces = 0
	let shortest_leading_spaces_run = 0

	let ccomment = 0
	let podcomment = 0
	let triplequote = 0
	let backtick = 0
	let xmlcomment = 0


	" Main loop, check every line for leading whitespace
	let lines = getline(1, 1024)
	for line in lines
		if !len(line) || line =~# '^\s*$'
			continue
		endif

		"{{{ Check for comments and ignore those lines (from tpope/vim-sleuth)
		if line =~# '^\s*/\*'
			let ccomment = 1
		endif
		if ccomment
			if line =~# '\*/'
			let ccomment = 0
			endif
			continue
		endif

		if line =~# '^=\w'
			let podcomment = 1
		endif
		if podcomment
			if line =~# '^=\%(end\|cut\)\>'
			let podcomment = 0
			endif
			continue
		endif

		if triplequote
			if line =~# '^[^"]*"""[^"]*$'
			let triplequote = 0
			endif
			continue
		elseif line =~# '^[^"]*"""[^"]*$'
			let triplequote = 1
		endif

		if backtick
			if line =~# '^[^`]*`[^`]*$'
			let backtick = 0
			endif
			continue
		elseif &filetype ==# 'go' && line =~# '^[^`]*`[^`]*$'
			let backtick = 1
		endif

		if line =~# '^\s*<\!--'
			let xmlcomment = 1
		endif
		if xmlcomment
			if line =~# '-->'
			let xmlcomment = 0
			endif
			continue
		endif
		"}}}

		"{{{ Check what the first character is and build heuristic based on it
		let leading_char = strpart(line, 0, 1)
		if leading_char == "\t"
			let has_leading_tabs += 1
		elseif leading_char == " "
			let has_leading_spaces += 1
			let spaces = strlen(matchstr(line, '^ \+'))
			if (shortest_leading_spaces_run == 0 || 
					\ spaces < shortest_leading_spaces_run) &&
					\ spaces < 9
					" Limit setting to not be completely off in arbitray text files
				let shortest_leading_spaces_run = spaces
			endif
		endif
		"}}}

	endfor

	"{{{ Set options according to found heuristic
	if has_leading_tabs && ! has_leading_spaces
		" tabs only, no spaces; use preferred tabstop (set in .vimrc or default 8)
		let settings = #{et:0, sts:0, sw:0}

	elseif ! has_leading_tabs && has_leading_spaces
		" spaces only, no tabs; leave tabstop as is
		let settings = #{et:1, sts:-1, sw:shortest_leading_spaces_run}

	elseif has_leading_tabs && has_leading_spaces
		" Check if one style dominates and set expandtab accordingly, otherwise use user preferred value (set in .vimrc or default off)
		if has_leading_tabs > 2 * has_leading_spaces
			let settings = #{sts:-1, sw:shortest_leading_spaces_run, ts:shortest_leading_spaces_run, et:0}
		elseif has_leading_spaces > 2 * has_leading_tabs
			let settings = #{sts:-1, sw:shortest_leading_spaces_run, ts:shortest_leading_spaces_run, et:1}
		else
			let settings = #{sts:-1, sw:shortest_leading_spaces_run, ts:shortest_leading_spaces_run}
		endif

	else
		" If file has no intendation so far, keep using what was set in .vimrc or defaults
		let settings = {}

	endif
	"}}}

	" only set options when they weren't already set by a modeline
	let modeline = s:WasSetByModeline(#{ts:"ts",sts:"sts",sw:"sw",et:"et"})
	for [option, value] in items(settings)
		if ! modeline[option]
			call setbufvar('', '&'.option, value)
		endif
	endfor

endfun

augroup auto_indent_settings
	autocmd!
	autocmd FileType * call s:IndentAutoDetect()
augroup END

command! -bang IndentAutoDetect call s:IndentAutoDetect()
command! -bang IndentAutoIndicator call s:IndentAutoIndicator("verbose")
