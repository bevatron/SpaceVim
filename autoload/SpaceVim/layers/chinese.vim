"=============================================================================
" chinese.vim --- SpaceVim chinese layer
" Copyright (c) 2016-2022 Wang Shidong & Contributors
" Author: Wang Shidong < wsdjeg@outlook.com >
" URL: https://spacevim.org
" License: GPLv3
"=============================================================================

""
" @section Chinese, layers-chinese
" @parentsection layers
" `chinese` layer provides Chinese specific function for SpaceVim.
" This layer is not loaded by default, to use this layer, add following
" snippet into your SpaceVim configuration file.
" >
"   [[layers]]
"     name = 'chinese'
" <
"
" @subsection key bindings
" >
"   Key binding     Description
"   SPC l c         check with ChineseLinter
"   SPC x g t       translate current word
"   SPC n c d       convert chinese number to digit 
" <
" 


function! SpaceVim#layers#chinese#plugins() abort
  let plugins = [
        \ ['yianwillis/vimcdoc'          , {'merged' : 0}],
        \ ['voldikss/vim-translator' , {'merged' : 0, 'on_cmd' : ['Translate', 'TranslateW', 'TranslateR', 'TranslateX']}],
        \ ['wsdjeg/ChineseLinter.vim'    , {'merged' : 0, 'on_cmd' : 'CheckChinese', 'on_ft' : ['markdown', 'text']}],
        \ ]
  if SpaceVim#layers#isLoaded('ctrlp')
    call add(plugins, ['vimcn/ctrlp.cnx', {'merged' : 0}])
  endif
  return plugins
endfunction

function! SpaceVim#layers#chinese#config() abort
  let g:_spacevim_mappings_space.x.g = {'name' : '+translate'}
  call SpaceVim#mapping#space#def('nnoremap', ['x', 'g', 't'], 'Translate'         , 'translate current word'  , 1)
  call SpaceVim#mapping#space#def('nnoremap', ['l', 'c']     , 'CheckChinese', 'Check with ChineseLinter', 1)
  let g:_spacevim_mappings_space.n.c = {'name' : '+Convert'}
  call SpaceVim#mapping#space#def('nmap', ['n', 'c', 'd'], '<Plug>ConvertChineseNumberToDigit', 'convert Chinese number to digit', 0, 1)
  " do not load vimcdoc plugin 
  let g:loaded_vimcdoc = 1
endfunction

function! SpaceVim#layers#chinese#health() abort
  call SpaceVim#layers#chinese#plugins()
  call SpaceVim#layers#chinese#config()
  return 1
endfunction

command! -nargs=0 -range ConvertChineseNumberToDigit :<line1>,<line2>call s:ConvertChineseNumberToDigit()
nnoremap <silent> <Plug>ConvertChineseNumberToDigit  :ConvertChineseNumberToDigit<cr>
vnoremap <silent> <Plug>ConvertChineseNumberToDigit  :ConvertChineseNumberToDigit<cr>
function! s:ConvertChineseNumberToDigit() range
  let save_cursor = getcurpos()
  let ChineseNumberPattern = '[???????????????????????????????????????????????????????????????????????????????????????????????????]\+'
  if mode() ==? 'n' && a:firstline == a:lastline
    let cword = expand('<cword>')
    let cword = substitute(cword, ChineseNumberPattern, '\=s:Chinese2Digit(submatch(0))', "g")
    let save_register_k = getreg("k")
    call setreg("k", cword)
    normal! viw"kp
    call setreg("k", save_register_k)
  else
    silent execute a:firstline . "," . a:lastline . 'substitute/' . ChineseNumberPattern . '/\=s:Chinese2Digit(submatch(0))/g'
  endif
  call setpos('.', save_cursor)
endfunction

function! s:Chinese2Digit(cnDigitString)
  let CN_NUM = {
        \ '???': 0, '???': 1, '???': 2, '???': 3, '???': 4, '???': 5, '???': 6, '???': 7, '???': 8, '???': 9,
        \ '???': 0, '???': 1, '???': 2, '???': 3, '???': 4, '???': 5, '???': 6, '???': 7, '???': 8, '???': 9,
        \ '???': 2, '???': 2, '???': '.'
        \ }
  let CN_UNIT = {
        \ '???': 10, '???': 10, '???': 100, '???': 100, '???': 1000, '???': 1000, '???': 10000, '???': 10000,
        \ '???': 100000000, '???': 100000000, '???': 1000000000000
        \ }

  if a:cnDigitString =~ '^[?????????????????????????????????????????????????????????????????????]\+$'
    let result = substitute(a:cnDigitString, ".", {m -> CN_NUM[m[0]]}, 'g')
  else
    let cnList = split(a:cnDigitString, "???")
    let integer = map(str2list(cnList[0]), 'nr2char(v:val)')  " ????????????
    let decimal = len(cnList) == 2 ? cnList[1] : [] " ????????????
    let unit = 0  " ????????????
    let parse = []  " ????????????
    while !empty(integer)
      let x = remove(integer, -1)
      if has_key(CN_UNIT, x)
        " ?????????????????????
        let unit = CN_UNIT[x]
        if unit == 10000 " ??????
          call add(parse, "w")
          let unit = 1
        elseif unit == 100000000 " ??????
          call add(parse, "y")
          let unit = 1
        elseif unit == 1000000000000  " ??????
          call add (parse, "z")
          let unit = 1
        endif
        continue
      else
        " ?????????????????????
        let dig = CN_NUM[x]
        if unit
          let dig *= unit
          let unit = 0
        endif
        call add(parse, dig)
      endif
    endwhile
    if unit == 10  " ??????10-19?????????
      call add(parse, 10)
    endif
    let result = 0
    let tmp = 0
    while !empty(parse)
      let x = remove(parse, -1)
      if type(x) == type("")
        if x == 'w'
            let tmp *= 10000
            let result += tmp
            let tmp = 0
        elseif x == 'y'
            let tmp *= 100000000
            let result += tmp
            let tmp = 0
        elseif x == 'z'
            let tmp *= 1000000000000
            let result += tmp
            let tmp = 0
        endif
      else
          let tmp += x
      endif
    endwhile
    let result += tmp
    if !empty(decimal)
      let decimal = substitute(decimal, ".", {m -> CN_NUM[m[0]]}, 'g')
      let result .= "." . decimal
    endif
  endif
  return result
endfunction

" function() wrapper
if v:version > 703 || v:version == 703 && has('patch1170')
  function! s:_function(fstr) abort
    return function(a:fstr)
  endfunction
else
  function! s:_SID() abort
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
  endfunction
  let s:_s = '<SNR>' . s:_SID() . '_'
  function! s:_function(fstr) abort
    return function(substitute(a:fstr, 's:', s:_s, 'g'))
  endfunction
endif

" vim:set et nowrap sw=2 cc=80:
