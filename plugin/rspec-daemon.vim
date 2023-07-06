let s:host = '0.0.0.0'
let s:port = 3002

augroup RSPEC-DAEMON
  autocmd!
  autocmd FileType rspec.ruby call s:define_commands()
  autocmd BufRead,BufNewFile *_spec.rb call s:define_commands()
augroup END

function! s:define_commands() abort
  command! -buffer RunRspec call s:run_rspec(expand('%'))
endfunction

function! s:make_request(file) abort
  return a:file
endfunction

" TODO: Send a request using "+job".
function! s:send_request(request) abort
  let l:cmd = printf('echo %s | nc -N %s %s', shellescape(a:request), shellescape(s:host), shellescape(s:port))

  call system(l:cmd)
endfunction

function! s:run_rspec(file) abort
  let l:request = s:make_request(a:file)

  call s:send_request(l:request)
endfunction

" vim: set tabstop=2 shiftwidth=2 expandtab :
