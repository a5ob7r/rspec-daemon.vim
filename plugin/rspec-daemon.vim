" This requires "socat" to communicate with rspec-daemon.

let s:host = '0.0.0.0'
let s:port = 3002

augroup RSPEC-DAEMON
  autocmd!
  autocmd FileType rspec.ruby call s:define_commands()
  autocmd BufRead,BufNewFile *_spec.rb call s:define_commands()
augroup END

function! s:define_commands() abort
  command! -buffer -bang -nargs=* -complete=file RunRSpec call s:run_rspec(<bang>0, <f-args>)
  command! -buffer -bang WatchAndRunRSpec call s:watch_and_run_rspec(<bang>0)
  command! -buffer UnwatchAndRunRSpec call s:unwatch_and_run_rspec()
endfunction

function! s:make_request(on_line, file) abort
  if a:on_line
    return printf('%s:%s', a:file, line('.'))
  else
    return a:file
  endif
endfunction

" TODO: Send a request using "+job".
" TODO: Send a request using "+channel".
function! s:send_request(request) abort
  let l:cmd = printf('echo %s | socat - TCP4:%s:%s', shellescape(a:request), shellescape(s:host), shellescape(s:port))

  call system(l:cmd)
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
    \ : ''

  if filereadable(l:spec)
    call s:run_rspec(a:on_line, l:spec)
  endif
endfunction

function! s:watch_and_run_rspec(on_line) abort
  call s:unwatch_and_run_rspec()

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
  try
    augroup! WATCH_AND_RUN_RSPEC
  catch /^Vim\%((\a\+)\)\=:E367:/
    " Ignore even if no the autocommand group.
  endtry
endfunction

" vim: set tabstop=2 shiftwidth=2 expandtab :
