" vim plugin to integrate shellbridge
" ----------------------------------------------------------------------

" fix alt key in terminal vim
if !has("gui_running")
  let c='a'
  while c <= 'z'
    exec "set <A-".c.">=\e".c
    exec "imap \e".c." <A-".c.">"
    let c = nr2char(1+char2nr(c))
  endw
  set ttimeout ttimeoutlen=50
endif

" get input from user in status bar
function! Prompt(query, default)
  call inputsave()
  let input = input(a:query, a:default)
  call inputrestore()
  redraw
  return input
endfunction

" default value of key mappings
function! s:SetDefault(name, default)
  if !exists(a:name)
    exec "let " . a:name . " = '" . a:default . "'"
  endif
endfunction
call s:SetDefault("g:shellbridge_init", "<m-n>")
call s:SetDefault("g:shellbridge_exec", "<m-n>")
call s:SetDefault("g:shellbridge_kill", "<m-d>")
call s:SetDefault("g:shellbridge_cleanup", "<m-c>")
call s:SetDefault("g:shellbridge_select", "<m-v>")
call s:SetDefault("g:shellbridge_next", "<m-j>")
call s:SetDefault("g:shellbridge_previous", "<m-k>")
call s:SetDefault("g:shellbridge_sort", "<m-s>")
call s:SetDefault("g:shellbridge_filter", "<m-f>")

" get line number of the number to append output
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
  let l = search("%".a:id."!|", "n")
  if l == 0
    return search("%current!|", "n")
  else
    return l
  endif
endfunction

function! shellbridge#get_cmd(line)
  let cmdLine = getline(a:line)
  " remove the meta tag if there is any
  let onlycmd = substitute(cmdLine, " *%.*| ", "", "")
  " remove any heading spaces
  return substitute(onlycmd, "^ *", "", "")
endfunction

" get id from current line meta data
" return 'done' when done
function! shellbridge#get_id_from_line(line)
  let content = getline(a:line)
  if content =~ "%done"
    return 'done'
  else
    return split(matchstr(content, "%\\d*"), '%')[0]
  endif
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
  exec a:line . "," . prevLineEnd . "s/!|/|/e"
  exec curLineNo
endfunction

function! shellbridge#update_meta(id, onlycmd, pad)
  let outputLine = a:pad . "%" . a:id . "!| " . a:onlycmd
  s/.*/\=outputLine/
endfunction

function! shellbridge#previous_cmd()
  return search("^%.*|", "bn")
endfunction

function! shellbridge#next_cmd()
  return search("^%.*|", "n")
endfunction

function! shellbridge#init()
  if v:servername == ""
    echoerr "Please start vim with --servername option" | return
  endif
  " register highlight group indicating done!
  tabnew
  setl nowrap conceallevel=2 concealcursor=inv
  setl noai nocin nosi inde= sts=0 sw=2 ts=2
  setl ft=sh
  hi shellbridge_done guifg=darkgray
  " syn clear shellbridge_done
  syn match shellbridge_done /%done|.*\(\n .*\)*/ contains=XXXConcealed
  syntax match XXXConcealed /%.*|/ conceal cchar=›

  let mappings = [
    \["n", g:shellbridge_exec, ":call shellbridge#exec()<cr>"],
    \["i", g:shellbridge_exec, "<esc>:call shellbridge#exec()<cr>"],
    \["v", g:shellbridge_exec, "<esc>:call shellbridge#exec_multiline()<cr>"],
    \["n", g:shellbridge_kill, ":call shellbridge#kill()<cr>"],
    \["n", g:shellbridge_cleanup, ":call shellbridge#cleanup_indented(line('.'))<cr>"],
    \["n", g:shellbridge_select, ":call shellbridge#select_output()<cr>"],
    \["n", g:shellbridge_sort, ":call shellbridge#select_output()<cr>:!sort<cr>"],
    \["n", g:shellbridge_next, ":call search('%', '')<cr>"],
    \["n", g:shellbridge_previous, ":call search('%', 'b')<cr>"],
    \["n", g:shellbridge_filter, ":call shellbridge#filter()<cr>"]
  \]
  for mapping in mappings
    exec mapping[0] . "noremap <buffer> <silent> " . mapping[1] . ' ' . mapping[2]
  endfor
  " map alt-o to open filename with line number under cursor in a new tab
  nmap <m-o> <c-w>gF
  " print help message
  let help = "# Welcome to shellbridge, below are your key mappings\n
    \# " . g:shellbridge_exec . ": Execute commands\n
    \# " . g:shellbridge_kill . ": Kill a running process\n
    \# " . g:shellbridge_cleanup . ": Cleanup command output\n
    \# " . g:shellbridge_sort . ": Sort command output\n
    \# " . g:shellbridge_next . ": Jump to next command\n
    \# " . g:shellbridge_previous . ": Jump to previous command\n
    \# " . g:shellbridge_filter . ": Filter output\n
    \\n\n"
  0put =help
endfunction

" called by server.js
function! shellbridge#on_message(id, msg)
  let [oline, ocol] = [line('.'), col('.')] " backup cursor pos
  let cmdLine = shellbridge#get_line_of_id(a:id)
  if cmdLine > 0 " when last line exist
    if a:msg == "!!done" " command is done
      exec cmdLine . "s/%.*|/%done|/"
      return
    else
      let lastLine = shellbridge#get_last_line(cmdLine)
      let output = substitute(a:msg, "&#39;", "'", "g")
      let output = substitute(output, "", "", "g")
      let spad = indent(cmdLine) == 2 ? "    " : "  "
      let output = spad . substitute(output, "\n", "\n".spad, "g")
      exec "silent " . lastLine . "put =output"
      exec "silent normal! " . oline . "G" . ocol . "|"
      exec "nohlsearch"
      exec "redraw"
    endif
  endif
endfunction

" prompt user and filter output by input
function! shellbridge#filter()
  let l = line('.')
  let [s, e] = [l + 1, shellbridge#get_last_line(l)]
  if s <= e
    let key = Prompt("Filter Key: ", "")
    if key != "" | exec s . "," . e . "v/" . key . "/d" | endif
    exec l
  else
    echo "No output found"
  endif
endfunction

" called in vim key binding
function! shellbridge#exec()
  let execline = line('.')
  let ind = indent(execline)
  let onlycmd = shellbridge#get_cmd(execline)

  let id = -1
  if ind > 0 " sub-cmd
    let prevLine = shellbridge#previous_cmd()
    if prevLine > 0 && prevLine < execline
      call shellbridge#cleanup_active_flags(prevLine)
      let id = shellbridge#get_id_from_line(prevLine)
      if id == "done"
        echo 'Original command is ended already'
        return
      endif
      call shellbridge#update_meta(id, onlycmd, '  ')
    endif
  else " primary cmd
    call shellbridge#cleanup_active_flags(execline)
    call shellbridge#update_meta('current', onlycmd, '')
  endif
  call shellbridge#cleanup_indented(execline)
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
      exec nend . 's/\</%pending| /'
    endif
    let nend -= 1
  endwhile

  while 1
    let l = search("%pending|")
    if l == 0 | break | endif
    call shellbridge#exec()
    sleep 50ms
  endwhile
endfunction

function! shellbridge#kill()
  let id = shellbridge#get_id_from_line('.')
  if id != "done"
    call system("shellbridge -k '" . getline('.') . "'")
  else
    echo "Command is ended already"
  endif
endfunction

exec "nnoremap " . g:shellbridge_init . ' :call shellbridge#init()<cr>'
