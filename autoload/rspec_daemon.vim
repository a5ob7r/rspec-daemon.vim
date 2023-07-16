" This requires "nc" or "socat" to communicate with rspec-daemon.
"
" TODO: Send a request using a Vim native way such as "+channel".

let s:cmdfmt =
  \ has('osxdarwin') ? 'echo %s | /usr/bin/nc -G 0 %s %s' :
  \ executable('socat') ? 'echo %s | socat - TCP4:%s:%s' :
  \ 'echo %s | nc -N %s %s'

function! s:rspec_daemon_host() abort
  return get(b:, 'rspec_daemon_host', get(g:, 'rspec_daemon_host', '0.0.0.0'))
endfunction

function! s:rspec_daemon_port() abort
  return get(b:, 'rspec_daemon_port', get(g:, 'rspec_daemon_port', 3002))
endfunction

function! s:append_line_number(filepath, number) abort
  return empty(a:filepath) ? '' : printf('%s:%s', a:filepath, a:number)
endfunction

function! s:infer_spec_path(filepath)
  let l:spec =
    \ a:filepath =~# '^spec/.\+_spec.rb$' ? a:filepath :
    \ a:filepath =~# '^app/controllers/.\+_controller.rb$' ? substitute(a:filepath, '^app/controllers/\(.\+\)_controller.rb$', 'spec/requests/\1_spec.rb', '') :
    \ a:filepath =~# '^app/models/.\+.rb$' ? substitute(a:filepath, '^app/models/\(.\+\).rb$', 'spec/models/\1_spec.rb', '') :
    \ a:filepath =~# '^lib/.\+.rb$' ? substitute(a:filepath, '^lib/\(.\+\).rb$', 'spec/\1_spec.rb', '') :
    \ ''

  return filereadable(l:spec) ? l:spec : ''
endfunction

function! s:send_request(request) abort
  let l:cmd = printf(s:cmdfmt, shellescape(a:request), shellescape(s:rspec_daemon_host()), shellescape(s:rspec_daemon_port()))

  if has('job')
    call job_start(['sh', '-c', l:cmd])
  else
    call system(l:cmd)
  endif
endfunction

function! rspec_daemon#run_rspec(on_line, arguments) abort
  let l:request =
    \ !empty(a:arguments) ? join(a:arguments) :
    \ a:on_line ? s:append_line_number(s:infer_spec_path(expand('%')), line('.')) :
    \ s:infer_spec_path(expand('%'))

  if !empty(l:request)
    call s:send_request(l:request)
  endif
endfunction

function! rspec_daemon#watch_and_run_rspec(on_line) abort
  augroup WATCH_AND_RUN_RSPEC
    autocmd!

    execute printf("autocmd BufWritePost,FileWritePost *.rb if bufnr('%%') == expand('<abuf>') | call rspec_daemon#run_rspec(%d, []) | endif", a:on_line)
  augroup END
endfunction

function! rspec_daemon#unwatch_and_run_rspec() abort
  augroup WATCH_AND_RUN_RSPEC
    autocmd!
  augroup END
endfunction

" vim: set tabstop=2 shiftwidth=2 expandtab :
