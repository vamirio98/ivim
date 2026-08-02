vim9script

noremap <leader>f <Cmd>call stargate#OKvim(1)<CR>
noremap <leader>F <Cmd>call stargate#OKvim(2)<CR>

g:stargate_name = 'Master'

Plug 'monkoose/vim9-stargate'

# set highlight after plugin load finishing to avoid color miss
augroup VcSitePlugStargate
  au!
  au VimEnter * hi! link StargateFocus Comment
  au VimEnter * hi! link StargateDesaturate Comment
  au VimEnter * hi! link StargateMain Search
  au VimEnter * hi! link StargateSecondary IncSearch
augroup END
