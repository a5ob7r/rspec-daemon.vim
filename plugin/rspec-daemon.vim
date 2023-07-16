if get(g:, 'rspec_daemon_loaded', 0)
  finish
endif

let g:rspec_daemon_loaded = 1

augroup RSPEC_DAEMON_COMMANDS
  autocmd!
  autocmd FileType ruby,rspec,rspec.ruby,ruby.rspec call s:define_commands()
augroup END

function! s:define_commands() abort
  command! -buffer -bang -nargs=* -complete=file RunRSpec call rspec_daemon#run_rspec(<bang>0, <f-args>)
  command! -buffer -bang WatchAndRunRSpec call rspec_daemon#watch_and_run_rspec(<bang>0)
  command! -buffer UnwatchAndRunRSpec call rspec_daemon#unwatch_and_run_rspec()
endfunction

" vim: set tabstop=2 shiftwidth=2 expandtab :
