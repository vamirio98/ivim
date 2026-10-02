vim9script

import autoload 'util/path.vim' as mPath
import autoload 'util/str.vim' as mStr
import autoload 'util/msg.vim' as mMsg

import autoload 'tui/confirm.vim' as mConfirm


export def File(): string
    if !exists('g:thisSession')
        return null_string
    endif
    return ConfigFile()
enddef


def ConfigFile(): string
    var projCfgDir = mPath.Parent(g:thisSession)
    return mPath.Joinpath(projCfgDir, 'project.ini')
enddef


export def Read(): dict<dict<string>>
    if !exists('g:thisSession')
        return null_dict
    endif

    var fpath = ConfigFile()
    if !mPath.IsFile(fpath)
        return null_dict
    endif

    try
        var body: list<string> = readfile(fpath)
        var sections: dict<any> = {}
        var current: string = 'default'
        for line in body
            var t: string = mStr.Strip(line)
            if t == ''
                continue
            elseif t =~ '^[;#].*$'  # comment
                continue
            elseif t =~ '^\[.*\]$'
                current = substitute(t, '\v^\[\s*(.{-})\s*\]$', '\1', '')
                if !has_key(sections, current)
                    sections[current] = {}
                endif
                continue
            else
                var pos: number = stridx(t, '=')
                if pos < 0
                    continue
                endif

                var key = strpart(t, 0, pos)->mStr.Strip()
                var value = strpart(t, pos + 1)->mStr.Strip()
                if !has_key(sections, current)
                    sections[current] = {}
                endif
                sections[current][key] = value
            endif
        endfor
        return sections
    catch
        return null_dict
    endtry
enddef


export def Config(): void
    if !exists('g:thisSession')
        mMsg.Error('No project open')
        return
    endif
    var fpath = ConfigFile()
    var newFile: bool = false
    if !mPath.IsFile(fpath)
        mMsg.Error($'No project configuration file found, create it through ":VcProject save" first')
        return
    endif
    exec 'silent e' fpath
    exec 'normal! G'
    exec 'normal! $'
enddef
