" vim plugin to integrate shellbridge
" ----------------------------------------------------------------------

function! shellbridge#get_last_line(line)
  let last = line('$')
  let l = a:line
  let i = indent(l)
  let l += 1
  while (indent(l) > i || len(getline(l)) == 0)
    if l >= last | let l = last + 1 | break | endif
    let l += 1
  endwhile
  return l - 1
endfunction

function! shellbridge#get_line_of_id(id)
  let l = search("data:".a:id.",active|", "n")
  if l == 0
    return search("data:current,active|", "n")
  else
    return l
  endif
endfunction

function! shellbridge#get_cmd(line)
  let cmdLine = getline(a:line)
  let onlycmd = substitute(cmdLine, " *data\:.*| ", "", "")
  return substitute(onlycmd, "^  ", "", "")
endfunction

function! shellbridge#get_id_from_line(line)
  let content = getline(a:line)
  return split(matchstr(content, "data:\\d*"), ':')[1]
endfunction

function! shellbridge#form_cmd(id, onlycmd)
  let escaped_cmd = "'" . substitute(a:onlycmd, "=", '\\=', "") . "'"
  return join([
    \"shellbridge",
    \"-i", a:id,
    \"-s", v:servername,
    \"-d", getcwd(),
    \escaped_cmd
  \])
endfunction

function! shellbridge#cleanup_indented(line)
  let [s, e] = [a:line + 1, shellbridge#get_last_line(a:line)]
  if s <= e
    exec s . ',' . e . 'd' | exec s - 1
  endif
endfunction

function! shellbridge#select_output()
  let [s, e] = [line('.') + 1, shellbridge#get_last_line(line('.'))]
  if s <= e
    exec e
    normal V
    exec s
  endif
endfunction

function! shellbridge#cleanup_active_flags(line)
  let [curLineNo, prevLineEnd] = [line('.'), shellbridge#get_last_line(a:line)]
  exec a:line . "," . prevLineEnd . "s/,active|/|/e"
  exec curLineNo
endfunction

function! shellbridge#update_meta(id, onlycmd, pad)
  let outputLine = a:pad . "data:" . a:id . ",active| " . a:onlycmd
  s/.*/\=outputLine/
endfunction

function! shellbridge#previous_cmd()
  return search("^data:", "bn")
endfunction

function! shellbridge#next_cmd()
  return search("^data:", "n")
endfunction

function! shellbridge#new_cmd()
  if indent('.') == 0
    let cmdline = line('.')
  else
    let cmdline = shellbridge#previous_cmd()
  endif
  exec shellbridge#get_last_line(cmdline)
  normal o
endfunction

function! shellbridge#init()
  if v:servername == ""
    echo "Please start vim with --servername option"
    return
  endif
  setl nowrap conceallevel=2 concealcursor=incv
  setl noai nocin nosi inde= sts=0 sw=2 ts=2 ft=sh
  filetype indent off
  syntax match XXXConcealed /data:.*|/ conceal cchar=›
  " send cmd
  nnoremap <silent> <c-cr> :call shellbridge#exec()<cr>
  inoremap <silent> <c-cr> <esc>:call shellbridge#exec()<cr>
  vnoremap <silent> <c-cr> <esc>:call shellbridge#exec_multiline()<cr>
  " kill cmd/ clear output/ select output
  nnoremap <silent> <m-d> :call shellbridge#kill()<cr>
  nnoremap <silent> <m-c> :call shellbridge#cleanup_indented(line('.'))<cr>
  nnoremap <silent> <m-v> :call shellbridge#select_output()<cr>
  " jump to prev/next cmd
  nnoremap <silent> <m-j> :call search("data:", "")<cr>
  nnoremap <silent> <m-k> :call search("data:", "b")<cr>
  " sort output
  nnoremap <silent> <m-u> :call shellbridge#select_output()<cr>:!sort<cr>
  " new command
  nnoremap <silent> <c-space> :call shellbridge#new_cmd()<cr>i
endfunction

" called by server.js
function! shellbridge#on_message(id, msg)
  let [oline, ocol] = [line('.'), col('.')] " backup cursor pos
  let cmdLine = shellbridge#get_line_of_id(a:id)
  if cmdLine > 0 " when last line exist
    let lastLine = shellbridge#get_last_line(cmdLine)
    let output = substitute(a:msg, "&#39;", "'", "g")
    let output = substitute(output, "", "", "g")
    let spad = indent(cmdLine) == 2 ? "    " : "  "
    let output = spad . substitute(output, "\n", "\n".spad, "g")
    exec "silent " . lastLine . "put =output"
    exec "silent normal! " . oline . "G" . ocol . "|"
    exec "redraw"
  endif
endfunction

" called in vim key binding
function! shellbridge#exec()
  let execline = line('.')
  let onlycmd = shellbridge#get_cmd(execline)
  let ind = indent(execline)
  if ind != 0 && ind != 2
    echo "Indentation must be either 0 or 2" | return
  end
  call shellbridge#cleanup_indented(execline)

  let id = -1
  if ind == 2 " sub-cmd
    let prevLine = shellbridge#previous_cmd()
    if prevLine > 0 && prevLine < execline
      call shellbridge#cleanup_active_flags(prevLine)
      let id = shellbridge#get_id_from_line(prevLine)
      call shellbridge#update_meta(id, onlycmd, '  ')
    endif
  else " primary cmd
    call shellbridge#cleanup_active_flags(execline)
    call shellbridge#update_meta('current', onlycmd, '')
  endif

  let output = system(shellbridge#form_cmd(id, onlycmd))

  if ind == 0 " primary cmd
    let id = substitute(output, "\n$", "", "")
    call shellbridge#update_meta(id, onlycmd, '')
  end
endfunction

function! shellbridge#exec_multiline()
  let [nstart, nend] = [line("'<"), line("'>")]
  let ind = indent(nstart)
  while nend >= nstart
    if indent(nend) != ind
      exec nend | normal dd
    else
      exec nend . 's/\</data:pending| /'
    endif
    let nend -= 1
  endwhile

  while 1
    let l = search("data:pending|")
    if l == 0 | break | endif
    call shellbridge#exec()
    sleep 50ms
  endwhile
endfunction

function! shellbridge#kill()
  call system("shellbridge -k '" . getline('.') . "'")
endfunction

nnoremap <m-n> :tabnew<cr>:call shellbridge#init()<cr>
