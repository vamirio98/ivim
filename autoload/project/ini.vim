vim9script

import autoload 'util/path.vim' as mPath
import autoload 'util/str.vim' as mStr
import autoload 'util/msg.vim' as mMsg

import autoload 'tui/confirm.vim' as mConfirm

import autoload 'project/history.vim' as mHistory


def ConfigFile(): string
    return mPath.Joinpath(g:thisProject, '.vim/vc/project/project.ini')
enddef


export def Read(): dict<any>
    if !exists('g:thisProject')
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
                current = substitute(t, '\v^\[\s*(.\{-})\\s*]$', '\1', '')
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
    catch
        return null_dict
    endtry

    return null_dict
enddef


export def Config(): void
    if !exists('g:thisProject')
        mMsg.Error('No project open')
        return
    endif
    var fpath = ConfigFile()
    var newFile: bool = false
    if !mPath.IsFile(fpath)
        if mConfirm.Confirm('No local project configuration file found, create it?',
                ['&Yes', '&No'], 1, 'Vc Project') != 1
            return
        endif
        mMsg.Warn($'Creating {fnamemodify(fpath, ':~:.')}')
        newFile = true
    endif

    var fdir = fnamemodify(fpath, ':h')
    if !mPath.IsDir(fdir)
        mkdir(fdir, 'p')
    endif
    exec 'silent e' fpath
    if newFile
        var bnr: number = bufnr('%')
        setbufline(bnr, 1, '[info]')
        setbufline(bnr, 2, 'name = ')
        exec 'normal! G'
        :startinsert!
    endif
enddef
