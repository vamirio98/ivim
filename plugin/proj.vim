vim9script

# use session to simulate project layout

import autoload 'util/msg.vim' as mMsg
import autoload 'util/proj.vim' as mProj
import autoload 'util/path.vim' as mPath
import autoload 'tool/plug.vim' as mPlug

command! -nargs=0 VcRoot mMsg.Info(mProj.Root())

if !get(g:, 'vcProjEnable', 1)
    finish
endif

if exists('g:vc_proj_loaded')
    finish
endif


g:vcDataDir = get(g:, 'vcDataDir', resolve(expand('~/.local/share/vim/vc')))
g:vcProjDir = get(g:, 'vcProjDir', mPath.Joinpath(g:vcDataDir, 'project'))
# auto update project when leave vim
g:vcAutoUpdateProj = get(g:, 'vcAutoUpdateProj')

var s_dir = g:vcProjDir

if !isdirectory(s_dir)
    mkdir(s_dir, 'p')
endif


def g:VcProjList(arglead: string, ..._): list<string>
    if !isdirectory(s_dir)
        return []
    endif

    var files: list<string> = globpath(s_dir, arglead .. '*')
        ->split('\n')->map((_, v) => fnamemodify(v, ':t'))
    return files
enddef


def WriteProjFile(fpath: string): void
    exec 'silent mksession!' fpath
enddef

def g:VcProjSave(bang: bool = false, a_name: string = null_string,
        a_silent: bool = false): void
    var name = a_name
    if name == null
        name = input('Project name: ', mProj.Root()->fnamemodify(':t'),
            'customlist,g:VcProjList')
    endif
    if empty(name)
        mMsg.Warn('No project name')
        return
    endif

    var fpath: string = mPath.Joinpath(s_dir, name)
    if mPath.Exists(fpath) && !bang
        var choice: number = confirm($'{name} is already exists, overwrite?',
            "&Yes\n&No", 2)
        if choice != 1
            return
        endif
    endif

    WriteProjFile(fpath)

    if !a_silent
        mMsg.Info($'Saved project [{name}]')
    endif
enddef


def g:VcProjLoad(a_name: string = null_string, a_silent: bool = false): void
    var name: string = a_name
    if name == null
        name = input('Project name: ', '', 'customlist,g:VcProjList')
    endif
    if empty(name)
        mMsg.Warn('No project name')
        return
    endif

    var fpath: string = mPath.Joinpath(s_dir, name)
    if !mPath.Exists(fpath)
        mMsg.Error($'{fpath} not found')
        return
    endif

    # remove all buffers first
    bufdo bd
    exec 'source' fnameescape(fpath)

    if !a_silent
        mMsg.Info($'Loaded project [{name}]')
    endif
enddef


def g:VcProjDelete(bang: bool = false, a_name: string = null_string,
        a_silent: bool = false): void
    if name == null
        name = input('Project name: ', '', 'customlist,g:VcProjList')
    endif
    if empty(name)
        mMsg.Warn('No project name')
        return
    endif

    var fpath: string = mPath.Joinpath(s_dir, name)
    if !mPath.Exists(fpath)
        mMsg.Error($'{fpath} not found')
        return
    endif

    if !bang
        var choice: number = confirm($'Delete project {name}?',
            "&Yes\n&No", 2)
        if choice != 1
            return
        endif
    endif
    delete(fpath)

    if !a_silent
        mMsg.Warn($'Deleted project [{name}]')
    endif
enddef


def g:VcProjClose(): void
    if exists('v:this_session') && mPath.Exists(v:this_session)
        WriteProjFile(fnameescape(v:this_session))
        v:this_session = ''
    endif
    bufdo bd
enddef


command! -nargs=? -bar -bang -complete=customlist,g:VcProjList
            \ VcProjSave g:VcProjSave(<bang>0, <f-args>)
command! -nargs=? -bar -bang -complete=customlist,g:VcProjList
            \ VcProjLoad g:VcProjLoad(<bang>0, <f-args>)
command! -nargs=? -bar -bang -complete=customlist,g:VcProjList
            \ VcProjDelete g:VcProjDelete(<bang>0, <f-args>)
command! -nargs=0 -bar VcProjClose g:VcProjClose()


augroup VcPluginProj
    au!
    au VimLeavePre * if g:vcAutoUpdateProj &&
                \ exists('v:this_session') && mPath.Exists(v:this_session)
                \ | WriteProjFile(fnameescape(v:this_session)) | endif
augroup END


# fzf integration {{{ #
if mPlug.Has('fzf.vim')
    def SearchProj(): void
        var projs: list<string> = g:VcProjList('')
        fzf#run(fzf#wrap({
            source: projs,
            sink: (line) => g:VcProjLoad(line)
        }))
    enddef

    nnoremap <space>sp <scriptcmd>SearchProj()<cr>
endif
# }}} fzf integration #
