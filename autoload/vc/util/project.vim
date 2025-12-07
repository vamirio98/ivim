vim9script

import autoload "./os.vim"
import autoload "./path.vim"


#----------------------------------------------------------------------
# guess root
#----------------------------------------------------------------------
def GuessRoot(filename: string, markers: list<string>): string
    var fullname: string = path.Abspath(filename)
    var pivot: string = fullname
    if !isdirectory(pivot)
        pivot = fnamemodify(pivot, ':h')
    endif
    while true
        var prev: string = pivot
        for marker in markers
            var newname: string = path.Join(pivot, marker)
            if newname =~ '\v(\*|\?|\[|\])'
                if !glob(newname)->empty()
                    return pivot
                endif
            elseif path.Exists(newname)
                return pivot
            endif
        endfor

        pivot = fnamemodify(pivot, ':h')
        if pivot == prev
            break
        endif
    endwhile
    throw 'error: can not found root'
enddef


#----------------------------------------------------------------------
# FindRoot({name}, {markers}, {strict})
# find project root
# {name} path, bufnr or '%'
# {markers} root markers
# {strict} if true, throw exception when not found, otherwise return the cwd
#----------------------------------------------------------------------
def FindRoot(name: any, markers: list<string> = null_list,
        strict: bool = false): string
    var fpath: string = null_string
    var root: string = null_string
    if type(name) == v:t_number
        var buf: number = (name < 0) ? bufnr('%') : name
        if !bufexists(buf)
            throw $'error: buffer {name} no exists'
        endif
        fpath = bufname(buf)
        root = getbufvar(buf, 'vc_root', null_string)
        if root != null
            return root
        elseif exists('g:vc_root') && g:vc_root != null_string
            return g:vc_root
        elseif exists('g:vc_root_locator')
            root = call(g:vc_root_locator, [buf])
            if root != null
                return root
            endif
        endif
        if getbufvar(buf, '&buftype') != null_string
            fpath = getcwd()
            return path.Abspath(fpath)
        endif
    elseif name == '%'
        fpath = path.Abspath(name)
        if exists('b:vc_root') && b:vc_root != null
            return b:vc_root
        elseif exists('t:vc_root') && t:vc_root != null
            return t:vc_root
        elseif exists('g:vc_root') && g:vc_root != null
            return g:vc_root
        elseif exists('g:vc_root_locator')
            root = call(g:vc_root_locator, [name])
            if root != null
                return root
            endif
        endif
    else
        fpath = path.Abspath(name)
    endif

    try
        return GuessRoot(fpath, markers)->path.Abspath()
    catch
        if strict
            throw v:exception
        endif
        # Not found: return parent directory of current file / directory itself.
        var fullname: string = path.Abspath(fpath)
        if isdirectory(fullname)
            return fullname
        endif
        return fnamemodify(fullname, ':h')
    endtry
enddef


#----------------------------------------------------------------------
# GetRoot({path} [, {markers}, {strict}])
# get project root
# {name} path, bufnr or '%'
# {markers} root markers
# {strict} if true, return null_string if not found, otherwise the cwd
#----------------------------------------------------------------------
export def GetRoot(fpath: string, markers: list<string> = null_list,
        strict: bool = false): string
    var newMarkers: list<string> = markers
    if newMarkers == null
        newMarkers = get(g:, 'vc_rootmarkers',
            ['.root', '.git', '.hg', '.svn', '.project'])
    endif
    return FindRoot(fpath, newMarkers, strict)
enddef


#----------------------------------------------------------------------
# current root
#----------------------------------------------------------------------
export def CurRoot(): string
    return GetRoot('%')
enddef
