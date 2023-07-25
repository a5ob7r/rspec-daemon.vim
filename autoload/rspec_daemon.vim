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

function! s:infer_spec_path(filepath)
  let l:spec =
    \ a:filepath =~# '^spec/.\+_spec.rb$' ? a:filepath :
    \ a:filepath =~# '^app/controllers/.\+_controller.rb$' ? substitute(a:filepath, '^app/controllers/\(.\+\)_controller.rb$', 'spec/requests/\1_spec.rb', '') :
    \ a:filepath =~# '^app/models/.\+.rb$' ? substitute(a:filepath, '^app/models/\(.\+\).rb$', 'spec/models/\1_spec.rb', '') :
    \ a:filepath =~# '^lib/.\+.rb$' ? substitute(a:filepath, '^lib/\(.\+\).rb$', 'spec/\1_spec.rb', '') :
    \ ''

  return filereadable(l:spec) ? l:spec : ''
endfunction

function! s:make_request(arguments, ...) abort
  let l:context = a:0 > 0 ? a:1 : {}
  let l:options = get(l:context, 'options', [])

  if !empty(a:arguments)
    return join(l:options + a:arguments)
  endif

  let l:spec = s:infer_spec_path(expand('%'))

  if empty(l:spec)
    return ''
  endif

  let l:ranges = get(l:context, 'ranges', [])

  return join([l:spec] + map(l:ranges, "join(range(v:val[0], v:val[1]), ':')"), ':')
endfunction

function! s:send_request(request) abort
  let l:cmd = printf(s:cmdfmt, shellescape(a:request), shellescape(s:rspec_daemon_host()), shellescape(s:rspec_daemon_port()))

  if has('job')
    call job_start(['sh', '-c', l:cmd])
  else
    call system(l:cmd)
  endif
endfunction

function! s:run(arguments, context) abort
  let l:request = s:make_request(a:arguments, a:context)

  if !empty(l:request)
    call s:send_request(l:request)
  endif
endfunction

function! rspec_daemon#run_rspec(arguments, context) abort
  let l:context =
    \ !empty(get(a:context, 'bang', '')) ? { 'ranges': [[line('.'), line('.')]] } :
    \ get(a:context, 'count', -1) > -1 ? { 'ranges': [[a:context['line1'], a:context['line2']]] } :
    \ {}

  call s:run(a:arguments, l:context)
endfunction

function! s:watch(bufnr, on_line) abort
  if bufnr('%') != a:bufnr
    return
  endif

  let l:context = a:on_line ? { 'bang': '!' } : {}
  call rspec_daemon#run_rspec([], l:context)
endfunction

function! rspec_daemon#watch_and_run_rspec(on_line) abort
  augroup WATCH_AND_RUN_RSPEC
    autocmd!

    execute printf("autocmd BufWritePost,FileWritePost *.rb call s:watch(expand('<abuf>'), %d)", a:on_line)
  augroup END
endfunction

function! rspec_daemon#unwatch_and_run_rspec() abort
  augroup WATCH_AND_RUN_RSPEC
    autocmd!
  augroup END
endfunction

" vim: set tabstop=2 shiftwidth=2 expandtab :
