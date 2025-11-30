vim9script

const DEFAULT_OPT = {
  'pos': 'center',
  'border': [1, 1, 1, 1],
  'borderchars': ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
}

# :h popup_create-arguments
export def Create(content: any, option: dict<any> = null_dict): number
  var opt: dict<any> = option == null ? {} : deepcopy(option)
  opt.pos = get(opt, 'pos', DEFAULT_OPT.pos)
  opt.border = get(opt, 'border', DEFAULT_OPT.border)
  opt.borderchars = get(opt, 'borderchars', DEFAULT_OPT.borderchars)

  return popup_create(content, opt)
enddef
