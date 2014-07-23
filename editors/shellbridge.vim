" shellbridge
" in order to make some interactive cmd works, please feed some parameters
"   ssh:           ssh -tt
"   mysql:         mysql -n
"   redis-cli:     (fine with default)
" ----------------------------------------------------------------------

function! shellbridge#get_list_line(line)
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

function! shellbridge#get_current_cmd()
  let cmdLine = getline('.')
  let onlycmd = substitute(cmdLine, " *data\:\\d*[,active]*| ", "", "")
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

function! shellbridge#cleanup_indented()
  let [s, e] = [line('.') + 1, shellbridge#get_list_line(line('.'))]
  if s <= e
    exec s . ',' . e . 'd' | exec s - 1
  endif
endfunction

function! shellbridge#select_output()
  let [s, e] = [line('.') + 1, shellbridge#get_list_line(line('.'))]
  if s <= e
    exec e
    normal V
    exec s
  endif
endfunction

function! shellbridge#cleanup_active_flags(line)
  let [curLineNo, prevLineEnd] = [line('.'), shellbridge#get_list_line(a:line)]
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
  exec shellbridge#get_list_line(cmdline)
  normal o
endfunction

function! shellbridge#init()
  setl nowrap conceallevel=2 concealcursor=incv
  setl noai nocin nosi inde= sts=0 sw=2 ts=2 ft=sh
  filetype indent off
  syntax match XXXConcealed /data:.*|/ conceal cchar=›
  " send cmd
  nnoremap <c-cr> :call shellbridge#exec()<cr>
  inoremap <c-cr> <esc>:call shellbridge#exec()<cr>
  " kill cmd/ clear output/ select output
  nnoremap <m-d> :call shellbridge#kill()<cr>
  nnoremap <m-c> :call shellbridge#cleanup_indented()<cr>
  nnoremap <m-v> :call shellbridge#select_output()<cr>
  " jump to prev/next cmd
  nnoremap <m-j> :call search("data:", "")<cr>
  nnoremap <m-k> :call search("data:", "b")<cr>
  " sort output
  nnoremap <m-u> :call shellbridge#select_output()<cr>:!sort<cr>
  " new command
  nnoremap <c-space> :call shellbridge#new_cmd()<cr>i
endfunction

" called by server.js
function! shellbridge#on_message(id, msg)
  let [oline, ocol] = [line('.'), col('.')] " backup cursor pos
  let cmdLine = shellbridge#get_line_of_id(a:id)
  if cmdLine > 0 " when last line exist
    let lastLine = shellbridge#get_list_line(cmdLine)
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
  let onlycmd = shellbridge#get_current_cmd()
  let ind = indent('.')
  if ind != 0 && ind != 2
    echo "Indentation must be either 0 or 2"
    return
  end
  call shellbridge#cleanup_indented()

  let id = -1
  if ind == 2 " sub-cmd
    let prevLine = shellbridge#previous_cmd()
    if prevLine > 0 && prevLine < line('.')
      call shellbridge#cleanup_active_flags(prevLine)
      let id = shellbridge#get_id_from_line(prevLine)
      call shellbridge#update_meta(id, onlycmd, '  ')
    endif
  else " primary cmd
    call shellbridge#cleanup_active_flags(line('.'))
    call shellbridge#update_meta('current', onlycmd, '')
  endif

  let output = system(shellbridge#form_cmd(id, onlycmd))

  if ind == 0 " primary cmd
    let id = substitute(output, "\n$", "", "")
    call shellbridge#update_meta(id, onlycmd, '')
  end
endfunction

function! shellbridge#kill()
  call system("shellbridge -k '" . getline('.') . "'")
endfunction

nnoremap <m-n> :tabnew<cr>:call shellbridge#init()<cr>
