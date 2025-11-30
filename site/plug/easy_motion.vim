vim9script

noremap <localleader>f <Cmd>call stargate#OKvim(1)<CR>

g:stargate_name = 'Master'

# set highlight after plugin load finishing to avoid color miss
augroup ivim_easy_motion
  au!
  au VimEnter * hi! link StargateFocus Comment
  au VimEnter * hi! link StargateDesaturate Comment
  au VimEnter * hi! link StargateMain Search
  au VimEnter * hi! link StargateSecondary IncSearch
augroup END
