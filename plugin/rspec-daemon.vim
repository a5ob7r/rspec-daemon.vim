" This requires "nc" or "socat" to communicate with rspec-daemon.
"
" TODO: Send a request using a Vim native way such as "+channel".

if get(g:, 'rspec_daemon_loaded', 0)
  finish
endif

let g:rspec_daemon_loaded = 1

let s:cmdfmt =
  \ has('osxdarwin') ? 'echo %s | /usr/bin/nc -G 0 %s %s' :
  \ executable('socat') ? 'echo %s | socat - TCP4:%s:%s' :
  \ 'echo %s | nc -N %s %s'

augroup RSPEC_DAEMON_COMMANDS
  autocmd!
  autocmd FileType ruby,rspec.ruby call s:define_commands()
  autocmd BufRead,BufNewFile *_spec.rb call s:define_commands()
augroup END

function! s:define_commands() abort
  command! -buffer -bang -nargs=* -complete=file RunRSpec call s:run_rspec(<bang>0, <f-args>)
  command! -buffer -bang WatchAndRunRSpec call s:watch_and_run_rspec(<bang>0)
  command! -buffer UnwatchAndRunRSpec call s:unwatch_and_run_rspec()
endfunction

function! s:rspec_daemon_host() abort
  return get(b:, 'rspec_daemon_host', get(g:, 'rspec_daemon_host', '0.0.0.0'))
endfunction

function! s:rspec_daemon_port() abort
  return get(b:, 'rspec_daemon_port', get(g:, 'rspec_daemon_port', 3002))
endfunction

function! s:make_request(on_line, file) abort
  if a:on_line
    return printf('%s:%s', a:file, line('.'))
  else
    return a:file
  endif
endfunction

function! s:send_request(request) abort
  let l:cmd = printf(s:cmdfmt, shellescape(a:request), shellescape(s:rspec_daemon_host()), shellescape(s:rspec_daemon_port()))

  if has('job')
    call job_start(['sh', '-c', l:cmd])
  else
    call system(l:cmd)
  endif
endfunction

function! s:run_rspec(on_line, ...) abort
  let l:request =
    \ a:0 >= 2 ? s:make_request(0, join(a:000)) :
    \ a:0 == 1 ? s:make_request(a:on_line, a:1) :
    \ s:make_request(a:on_line, expand('%'))

  call s:send_request(l:request)
endfunction

function! s:find_and_run_rspec(on_line, file) abort
  if a:file !=# expand('%')
    return
  endif

  let l:spec =
    \ a:file =~# '^spec/.\+_spec.rb$' ? a:file :
    \ a:file =~# '^app/controllers/.\+_controller.rb$' ? substitute(a:file, '^app/controllers/\(.\+\)_controller.rb$', 'spec/requests/\1_spec.rb', '') :
    \ a:file =~# '^app/models/.\+.rb$' ? substitute(a:file, '^app/models/\(.\+\).rb$', 'spec/models/\1_spec.rb', '')
    \ a:file =~# '^lib/.\+.rb$' ? substitute(a:file, '^lib/\(.\+\).rb$', 'spec/\1_spec.rb', '')
    \ : ''

  if filereadable(l:spec)
    call s:run_rspec(a:on_line, l:spec)
  endif
endfunction

function! s:watch_and_run_rspec(on_line) abort
  augroup WATCH_AND_RUN_RSPEC
    autocmd!

    if a:on_line
      autocmd BufWritePost,FileWritePost *.rb call s:find_and_run_rspec(1, expand('<afile>'))
    else
      autocmd BufWritePost,FileWritePost *.rb call s:find_and_run_rspec(0, expand('<afile>'))
    endif
  augroup END
endfunction

function! s:unwatch_and_run_rspec() abort
  augroup WATCH_AND_RUN_RSPEC
    autocmd!
  augroup END
endfunction

" vim: set tabstop=2 shiftwidth=2 expandtab :
