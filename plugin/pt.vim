" vim-pt

if &compatible || (exists('g:loaded_pt') && g:loaded_pt)
  finish
endif
let g:loaded_pt = 1

command! -bang -nargs=* -complete=file Pt       call pt#Pt('grep<bang>',<q-args>)
command! -bang -nargs=* -complete=file PtBuffer call pt#PtBuffer('grep<bang>',<q-args>)

" vim:et:ft=vim:fdm=marker:
