vim9script

noremap <localleader>f <Cmd>call stargate#OKvim(1)<CR>
noremap <localleader>F <Cmd>call stargate#OKvim(2)<CR>

g:stargate_name = 'Master'

# set highlight after plugin load finishing to avoid color miss
augroup vc_site_plug_easy_motion
  au!
  au VimEnter * hi! link StargateFocus Comment
  au VimEnter * hi! link StargateDesaturate Comment
  au VimEnter * hi! link StargateMain Search
  au VimEnter * hi! link StargateSecondary IncSearch
augroup END
