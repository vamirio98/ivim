vim9script

const DEFAULT = {
  'pos': 'center',
  'width': 0.6,
  'height': 0.4,
  'border': [1, 1, 1, 1],
  'borderchars': ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
}

export class Popup
  var id: number = -1
  var item: any
  var pos: string
  var width: any
  var height: any
  var border: list<number>
  var borderchars: list<string>

  def _GenOpt(): dict<any>
    var opt: dict<any> = {}
    opt.pos = this.pos
    opt.minwidth = type(this.width) == v:t_number ?
      this.width : float2nr(this.width * &columns)
    opt.maxwidth = opt.minwidth
    opt.minheight = type(this.height) == v:t_number ?
      this.height : float2nr(this.height * &lines)
    opt.maxheight = opt.minheight
    opt.border = this.border
    opt.borderchars = this.borderchars

    return opt
  enddef

  def new(item: any, option: dict<any> = null_dict)
    # TODO: `item` can be a function called each time `Show()`
    this.item = deepcopy(item)

    var opt: dict<any> = option == null ? {} : deepcopy(option)
    this.pos = get(opt, 'pos', DEFAULT.pos)
    this.width = get(opt, 'width', DEFAULT.width)
    this.height = get(opt, 'height', DEFAULT.height)
    this.border = get(opt, 'border', DEFAULT.border)
    this.borderchars = get(opt, 'borderchars', DEFAULT.borderchars)
  enddef

  # :h popup_create-arguments
  def Show()
    this.id = popup_create(this.item, this._GenOpt())
  enddef

  def Hide()
    popup_close(this.id)
    this.id = -1
  enddef
endclass
