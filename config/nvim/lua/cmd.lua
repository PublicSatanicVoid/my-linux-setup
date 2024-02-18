-- Define :Focus command to center the window
vim.cmd [[
function! CenterContent()
    let l:textwidth = 120

    let l:width = winwidth(0)
    let l:margin = (l:width - l:textwidth) / 2

    setlocal nosplitright
    vsplit
    enew
    setlocal nomodifiable
    setlocal nonumber
    setlocal norelativenumber
    setlocal fillchars=eob:\ "
    execute 'vertical resize ' . l:margin
    wincmd l
    setlocal splitright
    vsplit
    enew
    setlocal nomodifiable
    setlocal nonumber
    setlocal norelativenumber
    setlocal fillchars=eob:\ "
    execute 'vertical resize ' . l:margin
    wincmd h
endfunction
command! Focus call CenterContent()

function! UnCenterContent()
    wincmd h
    q
    wincmd l
    q
endfunction
command! UnFocus call UnCenterContent()
]]

