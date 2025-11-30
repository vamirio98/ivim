vim9script

# From https://github.com/girishji/vimcomplete/

import autoload '../lib/ui.vim' as ui

export var defaultKindItems = [
  # text, symbol, icon
  [],
  ['Text',           't', "󰉿"],
  ['Method',         'm', "󰆧"],
  ['Function',       'f', "󰊕"],
  ['Constructor',    'C', ""],
  ['Field',          'F', "󰜢"],
  ['Variable',       'v', "󰀫"],
  ['Class',          'c', "󰠱"],
  ['Interface',      'i', ""],
  ['Module',         'M', ""],
  ['Property',       'p', "󰜢"],
  ['Unit',           'u', "󰑭"],
  ['Value',          'V', "󰎠"],
  ['Enum',           'e', ""],
  ['Keyword',        'k', "󰌋"],
  ['Snippet',        'S', ""],
  ['Color',          'C', "󰏘"],
  ['File',           'f', "󰈙"],
  ['Reference',      'r', "󰈇"],
  ['Folder',         'F', "󰉋"],
  ['EnumMember',     'E', ""],
  ['Constant',       'd', "󰏿"],
  ['Struct',         's', "󰙅"],
  ['Event',          'E', ""],
  ['Operator',       'o', "󰆕"],
  ['TypeParameter',  'T', "󰉿"],
  ['Buffer',         'B', ""],
  ['Dictionary',     'D', "󰉿"],
  ['Word',           'w', ""],
  ['Option',         'O', "󰘵"],
  ['Abbrev',         'a', ""],
  ['EnvVariable',    'e', ""],
  ['URL',            'U', ""],
  ['Command',        'c', "󰘳"],
  ['Tmux',           'X', ""],
  ['Tag',            'G', "󰌋"],
]

def CreateKindsDict(): dict<list<string>>
  var d = {}
  for iter in defaultKindItems
    if !empty(iter)
      d[iter[0]] = [iter[1], iter[2]]
    endif
  endfor
  return d
enddef

export var defaultKinds: dict<list<string>> = CreateKindsDict()

# map LSP (and other) complete item kind to a character/symbol
export def GetItemKindValue(kind: any): string
  var kindValue: string
  if type(kind) == v:t_number # From LSP
    if kind > 26
      return ''
    endif
    kindValue = defaultKindItems[kind][0]
  else
    kindValue = kind
  endif
  if !defaultKinds->has_key(kindValue)
    ui.Error($'cmp: {kindValue} not found in dict')
    return ''
  endif
  # icon + text
  kindValue = $'{defaultKinds[kindValue][1]} {kindValue}'
  return kindValue
enddef

export def GetKindHighlightGroup(kind: any): string
  var kindValue: string
  if type(kind) == v:t_number # from LSP
    if kind > 26
      return 'PmenuKind'
    endif
    kindValue = defaultKindItems[kind][0]
  else
    kindValue = kind
  endif
  return 'PmenuKind' .. kindValue
enddef

export def InitKindHighlightGroups()
  for k in defaultKinds->keys()
    var grp = GetKindHighlightGroup(k)
    var tgt = hlget(k)->empty() ? 'PmenuKind' : k
    if hlget(grp)->empty()
      exec $'highlight! default link {grp} {k}'
    endif
  endfor
enddef
