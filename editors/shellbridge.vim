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

" get flag from a line
" %1a| xxxxx           : a(active)
" %14d| xxxxx          : d(done)
function! shellbridge#get_flag(line)
  let meta = matchstr(getline(a:line), "%\\d*.|")
  if meta == '' | return '' | endif
  return strpart(meta, strlen(meta)-2, 1)
endfunction

" get cmd part of current line (removed meta)
" remove the meta tag if there is any
" remove any leading spaces
function! shellbridge#extract_cmd(line)
  let cmd = substitute(getline(a:line), " *%\\d*.| ", "", "")
  return substitute(cmd, "^ *", "", "")
endfunction

function! shellbridge#update_meta(id, is_primary, ...)
  let flag = exists('a:1') ? a:1 : 'a'
  let lineno = exists('a:2') ? a:2 : line('.')
  let pad = a:is_primary ? '' : '  '
  let cmd = shellbridge#extract_cmd(lineno)
  let outputLine = pad . "%" . a:id . flag . "| " . cmd

  let oline = line('.')
  exec lineno
  s/.*/\=outputLine/
  exec oline
endfunction

" ask shellbridge server for the next id
function! shellbridge#request_next_id()
  return substitute(system('shellbridge --request-id'), '\n$', '', '')
endfunction

" send cmd part of current line to shellbridge server
function! shellbridge#execute_current_line(id)
  let c = shellbridge#extract_cmd('.')
  let escaped_cmd = "'" . substitute(c, "=", '\\=', "") . "'"
  let cmd = join([
    \"shellbridge",
    \"-i", a:id,
    \"-s", v:servername,
    \"-d", getcwd(),
    \escaped_cmd
  \])
  call system(cmd)
endfunction

" get line number of id
function! shellbridge#get_line_of_id(id)
  return search("%".a:id."a|", "n")
endfunction

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

" get id from current line meta data
" return 'done' when done
function! shellbridge#get_id_from_line(line)
  let content = getline(a:line)
  return split(matchstr(content, "%\\d*"), '%')[0]
endfunction

" change a to i for all meta data on id
" add e flag in substitute for not throwing error when not found
function! shellbridge#cleanup_active_flag(id)
  let [oline, ocol] = [line('.'), col('.')] " backup cursor pos
  exec "%s/%" . a:id . "a|/%" . a:id . "i|/e"
  exec "silent normal! " . oline . "G" . ocol . "|"
endfunction

" check if line is command (check if meta data exists)
function! shellbridge#is_command(line)
  let meta = matchstr(getline(a:line), "%\\d*.|")
  return meta != ''
endfunction

" cleanup output, triggered by user
function! shellbridge#user_cleanup_indented()
  let l = shellbridge#get_nearest_command()
  call shellbridge#cleanup_indented(l)
endfunction

" cleanup old output of a primary cmd or a sub cmd
function! shellbridge#cleanup_indented(line)
  let l = a:line
  let [s, e] = [l + 1, shellbridge#get_last_line(l)]
  if s > e | return | endif
  exec s . ',' . e . 'd' | exec s - 1
endfunction

" line select output
function! shellbridge#select_output()
  let l = shellbridge#get_nearest_command()
  let [s, e] = [l + 1, shellbridge#get_last_line(l)]
  if s > e | return | endif
  exec e | normal V
  exec s
endfunction

" get line number of prev cmd
function! shellbridge#previous_cmd()
  return search("^%\\d*.|", "bn")
endfunction

" get line number of next cmd
function! shellbridge#next_cmd()
  return search("^%\\d*.|", "n")
endfunction

" open a new tab in vim and initialize the shellbridge client
function! shellbridge#init()
  if v:servername == ""
    echoerr "Please start vim with --servername option" | return
  endif
  " register highlight group indicating done!
  tabnew
  setl nowrap conceallevel=2 concealcursor=inv
  setl noai nocin nosi inde= sts=0 sw=2 ts=2
  " setl ft=sh

  let mappings = [
    \["n", g:shellbridge_exec, ":call shellbridge#exec()<cr>"],
    \["i", g:shellbridge_exec, "<esc>:call shellbridge#exec()<cr>"],
    \["v", g:shellbridge_exec, "<esc>:call shellbridge#exec_multiline()<cr>"],
    \["n", g:shellbridge_kill, ":call shellbridge#kill()<cr>"],
    \["n", g:shellbridge_cleanup, ":call shellbridge#user_cleanup_indented()<cr>"],
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
    \# " . g:shellbridge_select . ": Line select command output\n
    \# " . g:shellbridge_sort . ": Sort command output\n
    \# " . g:shellbridge_next . ": Jump to next command\n
    \# " . g:shellbridge_previous . ": Jump to previous command\n
    \# " . g:shellbridge_filter . ": Filter output\n
    \\n\n"
  0put =help
  " syntax highlight commands that done
  " syn clear shellbridge_done
  syntax match XXXConcealed /%\d*.|/ conceal cchar=›
  hi comment guifg=darkgray
  syn match comment /#.*/
  hi shellbridge_done guifg=darkgray
  syn match shellbridge_done /%\d*d|.*\(\n .*\)*/ contains=XXXConcealed
endfunction

" called by server.js
function! shellbridge#on_message(id, msg)
  let [oline, ocol] = [line('.'), col('.')] " backup cursor pos
  let lineno = shellbridge#get_line_of_id(a:id)
  if lineno == 0 | return | endif " reject if not found
  if a:msg == "!!done" " command is done
    let primary_lineno = search("^%".a:id.".|", "n")
    call shellbridge#update_meta(a:id, 1, 'd', primary_lineno)
  else
    let lastLine = shellbridge#get_last_line(lineno)
    let output = substitute(a:msg, "&#39;", "'", "g")
    let output = substitute(output, "", "", "g")
    let spad = indent(lineno) == 2 ? "    " : "  "
    let output = spad . substitute(output, "\n", "\n".spad, "g")
    exec "silent " . lastLine . "put =output"
    exec "silent normal! " . oline . "G" . ocol . "|"
  endif
  exec "nohlsearch | redraw"
endfunction

" get current line of nearest command
function! shellbridge#get_nearest_command()
  let l = line('.')
  if !shellbridge#is_command(l)
    let l = search("%\\d*.|", "bn")
  endif
  return l
endfunction

" prompt user and filter output by input
function! shellbridge#filter()
  let l = shellbridge#get_nearest_command()
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
  let lineno = line('.')
  call shellbridge#cleanup_indented(lineno)

  let is_primary = indent(lineno) == 0
  let id = -1
  if is_primary
    let id = shellbridge#request_next_id()
    call shellbridge#update_meta(id, is_primary)
  else " sub cmd
    let prevLineNo = shellbridge#previous_cmd()
    if prevLineNo == 0 || prevLineNo >= lineno
      echo "Parent command not found" | return
    endif
    let id = shellbridge#get_id_from_line(prevLineNo)
    call shellbridge#cleanup_active_flag(id)
    if shellbridge#get_flag(prevLineNo) == 'd'
      echo 'Original command is ended already' | return
    endif
    call shellbridge#update_meta(id, is_primary)
  endif
  call shellbridge#execute_current_line(id)
endfunction

" execute multiple lines (line selected)
function! shellbridge#exec_multiline()
  let [nstart, nend] = [line("'<"), line("'>")]
  let ind = indent(nstart)
  let is_primary = ind == 0
  while nend >= nstart
    " depends on indentation, mark it executable or remove it
    if indent(nend) != ind
      exec nend | normal dd
    else
      call shellbridge#update_meta(0, is_primary, 'p', nend) " change to 0p
    endif
    let nend -= 1
  endwhile
  " execute executable lines
  while 1
    let l = search("%0p|")
    if l == 0 | break | endif
    call shellbridge#update_meta(0, is_primary) " change 0p to 0a
    call shellbridge#exec()
    sleep 100ms
  endwhile
endfunction

" kill a running process
function! shellbridge#kill()
  let id = shellbridge#get_id_from_line('.')
  if shellbridge#get_flag('.') == 'd'
    echo 'This command is ended already'
  else
    call system("shellbridge -k '" . id . "'")
  endif
endfunction

" map the init key to initialize shellbridge client
exec "nnoremap " . g:shellbridge_init . ' :call shellbridge#init()<cr>'
