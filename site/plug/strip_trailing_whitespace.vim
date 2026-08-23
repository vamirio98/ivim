vim9script

augroup VcSitePlugStripTrailingWhitespace
  au!
  au FileType dirvish b:strip_trailing_whitespace_enabled = 0
  au BufAdd * if &bt == 'popup'
    | b:strip_trailing_whitespace_enabled = 0 | endif
augrou END
