" This requires "socat" to communicate with rspec-daemon.

let s:host = '0.0.0.0'
let s:port = 3002

augroup RSPEC-DAEMON
  autocmd!
  autocmd FileType rspec.ruby call s:define_commands()
  autocmd BufRead,BufNewFile *_spec.rb call s:define_commands()
augroup END

function! s:define_commands() abort
  command! -buffer -bang -nargs=* -complete=file RunRspec call s:run_rspec(<bang>0, <f-args>)
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
  if a:0 > 0
    for l:file in a:000
      let l:request = s:make_request(0, l:file)

      call s:send_request(l:request)
    endfor
  else
    let l:request = s:make_request(a:on_line, expand('%'))

    call s:send_request(l:request)
  endif
endfunction

" vim: set tabstop=2 shiftwidth=2 expandtab :
