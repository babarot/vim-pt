" vim-pt

let s:save_cpo = &cpoptions
set cpoptions&vim

" pt#Version {{{
" pt#Version check if the version number that was given
" as an argument is larger than and return a boolean
function! pt#Version(...)
    let l:latest = system("pt --version")

    if len(a:000) == 0
        return l:latest
    endif

    if substitute(l:latest, "\\\.", "", "g") >= str2nr(a:0, 10)
        return 1
    else
        return 0
    endif
endfunction
"}}}

if exists('g:pt_args')
    let s:pt_args = g:pt_args
else
    let s:pt_args = pt#Version(177) ? "pt --nogroup --column" : "pt --nogroup"
endif
let s:pt_highlight = get(g:, 'pt_highlight', 1)

function! pt#Pt(cmd, args)
    " Get first argument in ["pt", "--nogroup", ...]
    let l:pt_bin = get(split(s:pt_args, " "), 0)

    " Check if pt exists
    if !executable(l:pt_bin)
        echoe printf("%s: command not found", l:pt_bin)
        return
    endif

    " If no pattern is given, search for the word under the cursor
    if empty(a:args)
        let l:grepargs = expand("<cword>")
    else
        let l:grepargs = a:args . join(a:000, ' ')
    end

    " Format, used to manage column jump
    if a:cmd =~# '-g$'
        let s:pt_format_backup=g:pt_format
        let g:pt_format="%f"
    elseif exists("s:pt_format_backup")
        let g:pt_format=s:pt_format_backup
    elseif !exists("g:pt_format")
        if pt#Version(177)
            let g:pt_format="%f:%l:%c:%m"
        else
            let g:pt_format="%f:%l:%m"
        endif
    endif

    let l:grepprg_bak = &grepprg
    let l:grepformat_bak = &grepformat
    let l:t_ti_bak = &t_ti
    let l:t_te_bak = &t_te
    try
        let &grepprg = s:pt_args
        let &grepformat = g:pt_format
        set t_ti=
        set t_te=
        silent! execute a:cmd . " " . escape(l:grepargs, '|')
    finally
        let &grepprg = l:grepprg_bak
        let &grepformat = l:grepformat_bak
        let &t_ti = l:t_ti_bak
        let &t_te = l:t_te_bak
    endtry

    if a:cmd =~# '^l'
        let l:match_count = len(getloclist(winnr()))
    else
        let l:match_count = len(getqflist())
    endif

    if a:cmd =~# '^l' && l:match_count
        exe "botright lopen"
        let l:matches_window_prefix = 'l' " we're using the location list
    elseif l:match_count
        exe "botright copen"
        let l:matches_window_prefix = 'c' " we're using the quickfix window
    endif

    redraw!

    " Define keybinds for pt buffer
    " It is limited only when there is a match
    if l:match_count
        exe 'nnoremap <silent> <buffer> e    <CR><C-w><C-w>:' . l:matches_window_prefix .'close<CR>'
        exe 'nnoremap <silent> <buffer> <CR> <CR><C-w><C-w>:' . l:matches_window_prefix .'close<CR>'
        exe 'nnoremap <silent> <buffer> p    <CR>:' . l:matches_window_prefix . 'open<CR>'
        exe 'nnoremap <silent> <buffer> q    :' . l:matches_window_prefix . 'close<CR>'
    else
        echom 'No matches for "'.a:args.'"'
    endif

    " Highlight matching words
    if s:pt_highlight
        exe 'syntax match ErrorMsg display /' . l:grepargs . '/'
    endif
endfunction

function! pt#PtBuffer(cmd, args)
    let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val)')
    let l:files = []
    for buf in l:bufs
        let l:file = fnamemodify(bufname(buf), ':p')
        if !isdirectory(l:file)
            call add(l:files, l:file)
        endif
    endfor
    call pt#Pt(a:cmd, a:args . ' ' . join(l:files, ' '))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:et:ft=vim:fdm=marker:
