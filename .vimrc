set uc=0 """no swapfile
set nocompatible
set autoindent
set nowrap
set number
set expandtab
set smarttab
set shiftwidth=2
set tabstop=2
set softtabstop=2
set mouse=a
set list
set listchars=tab:››

let g:GPGUseAgent=0

set hlsearch
"This unsets the "last search pattern" register by hitting return
nnoremap <CR> :noh<CR>

set hidden
set ofu=syntaxcomplete#Complete
set backspace=2
set ic
set history=9000

syntax on
colorscheme solarized
set background=dark

"""detect filetypes"""
au BufRead,BufNewFile *.hx set filetype=haxe
au Syntax haxe source ~/.vim/haxe/haxe.vim

au BufRead * call s:isHaskellScript()
function s:isHaskellScript()
  if match(getline(1), '\v#!.*run(ghc|haskell)') >= 0
    set filetype=haskell
  endif
endfunction

" override default ftplugin for python
au BufRead,BufNewFile *.py set shiftwidth=2 tabstop=2 softtabstop=2
""""""

hi TrailingWhitespace ctermbg=red guibg=red
autocmd CursorMoved  * match TrailingWhitespace /\%(\s\+\&\s*\%#\@!\)$/
autocmd CursorMovedI * match TrailingWhitespace /\%(\s\+\&\s*\%#\@!\)$/

"""keep cursor vertically centered while searching"""
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap g# g#zz
""""""

"""command repeat"""
nmap , @:
""""""

"""Quit"""
nmap <C-X><C-C> :qa!<CR>
imap <C-X><C-C> <Esc>:qa!<CR>

nmap <C-C> :q<CR>
imap <C-C> <Esc>:q<CR>
""""""

"""Undo"""
nmap <C-U>      u
imap <C-U> <Esc>uli

nmap <C-R>      <C-R>
imap <C-R> <Esc><C-R>li
""""""

"""word wrap"""
map <C-w><C-w> :s/\v(.{70}[^ ]*)/\1\r/g<CR>
map <C-w><C-h> :s/\v(.{70}[^ ]*)/\1\r--/g<CR>
""""""

"""Write"""
nmap <F3>      :w<CR>
imap <F3> <Esc>:w<CR>li
vmap <F3> :w<Del><CR>lv
""""""

"""meld"""
nmap <F2>      :Exec cd %:p:h; meld %:p &<CR>
imap <F2> <Esc>:Exec cd %:p:h; meld %:p &<CR>
""""""

"""git"""
nmap <F4>      :Exec cd %:p:h; git gui &<CR>
imap <F4> <Esc>:Exec cd %:p:h; git gui &<CR>
""""""

"""Run"""
nmap <F5> :1wincmd<space>w<CR>:w<CR>:Run<CR>
imap <F5> <ESC>:1wincmd<space>w<CR>:w<CR>:Run<CR>li
""""""

"""Clipboard"""
map <C-y> "+y
map <C-p> "+p
map <F9>  "*p

nmap <F7>      "+y
vmap <F7>      "+y

nmap <F8>      "+p
imap <F8> <ESC>"+pi
vmap <F8>      "+p
""""""

cmap now r! date "+\%Y-\%m-\%d \%a \%H:\%M"<CR>

command! -bar -range=% Reverse <line1>,<line2>g/^/m<line1>-1|nohl

" Disable readonly in vimdiff
if &diff
  set noro
endif

""":Exec cmd arg arg ..
" run external commands quietly
command -nargs=1 Exec
\ execute 'silent ! ' . <q-args>
\ | execute 'redraw! '

filetype plugin on
let g:omni_sql_no_default_maps = 1

function CSV()
  if &ft ==? "csv"
    %UnArrangeCol
    set filetype=""
  else
    set filetype=csv
    %ArrangeColumn
  endif
endfunction
command CSV call CSV()
command Csv call CSV()

function LoadTemp()
  LoadFileTemplate default
  :normal! Gddgg
endfunction
autocmd! BufNewFile * call LoadTemp()


let s:RunHeight = 12
command -nargs=* Run call Run(<f-args>)
function Run(...)
    1wincmd w
    let interpreter = strpart(getline(1),2)
    let abspath = expand("%:p")
    let arguments = join(a:000, " ")
    let call = interpreter . ' "' . abspath . '" ' . arguments

    if winnr("$") == 1
        below new
    endif

    2wincmd w
    execute "resize " . s:RunHeight
    let perlexp = 'print q(RunVimRun)x64 . <> . qq(\n);'
    execute "%! eval \"(".call." | perl -0777 -e '".perlexp."')2>&1\""
    let lines = getbufline(bufnr("%"),1,"$")
    %s/\v\_.*(RunVimRun){64}//

    if winnr("$") == 2
        below vnew
    endif

    3wincmd w
    let i = 1
    for l in lines
        call setline(i, l)
        let i += 1
    endfor
    %s/\v(RunVimRun){64}\_.*//

    1wincmd w
endfunction
command -nargs=* RunHeight call RunHeight(<f-args>)
function RunHeight(height, ...)
  let s:RunHeight = a:height
  call Run(a:000)
endfunction

nnoremap <C-S> :set spell!<CR>
inoremap <C-S> <ESC>:set spell!<CR>li

nnoremap <C-N> :call ToggleRelativeNumber()<CR>
function ToggleRelativeNumber()
    if &relativenumber
        set norelativenumber
        set number
    else
        set nonumber
        set relativenumber
    endif
endfunction

command -nargs=* BandCampToMusicBrainz call BandCampToMusicBrainz(<f-args>)
function BandCampToMusicBrainz()
  %s/\v^\s+\n//
  %s/\v(\d+)\.\n/\1 /
  %s/\v\s+$//
endfunction
