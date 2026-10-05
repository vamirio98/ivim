vim9script

import autoload "util/path.vim" as mPath
import autoload "util/os.vim" as mOs
import autoload 'util/str.vim' as mStr

import autoload 'tool/plug.vim' as mPlug


g:asynctasks_extra_config = get(g:, 'asynctasks_extra_config', [])
g:asynctasks_extra_config += [
    mPath.Resolve(mPath.Joinpath(g:vcHome,
        'site/asynctasks/tasks.ini')
    )
]

g:asyncrun_open = 6
g:asyncrun_rootmarks = g:vcRootmarkers
g:asyncrun_shell = mOs.IsWin() ? 'bash' : 'pwsh'
g:asynctasks_rtp_config = "asynctasks.ini"


# python will buffer everything written to stdout when running as a backgroup
# process, this can see the realtime output without calling `flush()`
$PYTHONUNBUFFERED = '1'


def ExecTask(line: string): void
    var pos = stridx(line, '<')
    if pos < 0
        return
    endif

    var name: string = line->strpart(0, pos)->mStr.Strip()
    if !empty(name)
        exec 'AsyncTask' fnameescape(name)
    endif
enddef


def SearchTask(): void
    var rows = asynctasks#source(&columns * 48 / 100)
    var tasks: list<string> = []
    for row in rows
        tasks += [ $'{row[0]}   {row[1]}  :  {row[2]}' ]
    endfor

    fzf#run(fzf#wrap({
        source: tasks,
        sink: ExecTask,
        options: '+m --nth 1 --inline-info --tac',
    }))
enddef


def Setup(): void
    if mPlug.Has('fzf.vim')
        nnoremap <space>pq <scriptcmd>SearchTask()<cr>
    endif
enddef


augroup SitePlugAsynctask
    au!
    au VimEnter * Setup()
augroup END
