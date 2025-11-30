vim9script

# From https://github.com/girishji/vimcomplete/

import autoload './util.vim'
import autoload '../lib/ui.vim'

export var options: dict<any> = {
  enable: true,
  bufferRelativePath: true,
  groupDirectoriesFirst: false,
  showPathSeparastorAtEnd: false,
}

var sep: string = (has('unix') || &shellslash) ? '/' : '\'

export def Completor(findstart: number, base: string): any
  if findstart
    var line = getline('.')->strpart(0, col('.') - 1)
    var prefix = line->matchstr('\f\+$')
    if !prefix->empty() &&
        !(line->matchstr('\c\vhttp(s)?(:)?(/){0,2}\S+$')->empty())
      return -2
    endif
    if prefix->empty() || prefix =~ '?$' || prefix !~ sep
      return -2
    endif
    # to inclue the leading '.'
    return col('.') - (strlen(prefix) + 1)
  endif

  var citems = []
  var cwd: string = ''
  try
    if base =~ ('^\.\.\?' .. sep) &&
        options.bufferRelativePath && expand('%:h') !=# '.'
      # not already in buffer dir, change directory to get
      # completions for paths relative to current buffer dir
      cwd = getcwd()
      exec $'cd {expand('%:p:h')}'
    endif
    var completions = getcompletion(base, 'file', 1)
    def IsDir(p: string): bool
      return isdirectory(fnamemodify(p, ':p'))
    enddef
    if options.groupDirectoriesFirst
      completions = completions->copy()->filter((_, v) => IsDir(v)) +
        completions->copy()->filter((_, v) => !IsDir(v))
    endif
    for item in completions
      var citem = item
      var itemlen = len(item)
      var isdir = IsDir(item)
      if isdir && item[itemlen - 1] == sep
        citem = item->slice(0, itemlen - 1)
      endif
      citems->add({
        word: citem,
        abbr: (options.showPathSeparastorAtEnd ? item : citem)->fnamemodify(':t'),
        kind: util.GetItemKindValue(isdir ? 'Folder' : 'File'),
        kind_hlgroup: util.GetKindHighlightGroup(isdir ? 'Folder' : 'File'),
      })
    endfor
  catch
      # on MacOS it does not complete /tmp/* (throws E344, looks for /prevate/tmp/...)
    ui.Error(v:exception)
  finally
    if !cwd->empty()
      exec $'cd {cwd}'
    endif
  endtry
  return citems
enddef
