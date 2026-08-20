vim9script

import autoload "./path.vim" as mPath


#----------------------------------------------------------------------
# guess root
#----------------------------------------------------------------------
def GuessRoot(filename: string, markers: list<string>): string
    var fullname: string = mPath.Resolve(filename)
    var pivot: string = fullname
    if !isdirectory(pivot)
        pivot = fnamemodify(pivot, ':h')
    endif
    while true
        var prev: string = pivot
        for marker in markers
            var newname: string = mPath.Joinpath(pivot, marker)
            if newname =~ '\v(\*|\?|\[|\])'
                if !glob(newname)->empty()
                    return pivot
                endif
            elseif mPath.Exists(newname)
                return pivot
            endif
        endfor

        pivot = fnamemodify(pivot, ':h')
        if pivot == prev
            break
        endif
    endwhile
    throw 'root not found'
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
            throw $'buffer {name} no exists'
        endif
        fpath = bufname(buf)
        root = getbufvar(buf, 'vcRoot', null_string)
        if root != null
            return root
        elseif exists('g:vcRoot') && g:vcRoot != null_string
            return g:vcRoot
        elseif exists('g:VcRootLocator')
            root = call(g:VcRootLocator, [buf])
            if root != null
                return root
            endif
        endif
        if getbufvar(buf, '&buftype') != null_string
            fpath = getcwd()
            return mPath.Resolve(fpath)
        endif
    elseif name == '%'
        fpath = mPath.Resolve(expand(name))
        if exists('b:vcRoot') && b:vcRoot != null
            return b:vcRoot
        elseif exists('t:vcRoot') && t:vcRoot != null
            return t:vcRoot
        elseif exists('g:vcRoot') && g:vcRoot != null
            return g:vcRoot
        elseif exists('g:VcRootLocator')
            root = call(g:VcRootLocator, [name])
            if root != null
                return root
            endif
        endif
    else
        fpath = mPath.Resolve(name)
    endif

    try
        return GuessRoot(fpath, markers)->mPath.Resolve()
    catch
        if strict
            throw v:exception
        endif
        # Not found: return parent directory of current file / directory itself.
        var fullname: string = mPath.Resolve(fpath)
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
export def GetRoot(fpath: string, a_markers: list<string> = null_list,
        strict: bool = false): string
    var markers: list<string> = a_markers
    if markers == null
        markers = get(g:, 'vcRootmarkers',
            ['.root', '.git', '.hg', '.svn', '.project'])
    endif
    return FindRoot(fpath, markers, strict)
enddef


#----------------------------------------------------------------------
# current root
#----------------------------------------------------------------------
export def Root(): string
    return GetRoot('%')
enddef
