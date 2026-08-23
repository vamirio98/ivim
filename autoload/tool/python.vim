vim9script

import autoload 'util/path.vim' as mPath
import autoload 'util/os.vim' as mOs
import autoload 'util/msg.vim' as mMsg

const kErrReqPython: string = 'require +python3 feature'
const kHasPython3: bool = has('python3')

var s_shellError: number = 0
# ensure `vim` module has been import for python
var s_vimImported: bool = false
# in vim9script, vim module in python can only access script level var, not
# function local var, see: https://github.com/vim/vim/issues/8573
var s_userArgs: any = null


def String(text: any): string
    return type(text) == v:t_string ? text : (
        type(text) == v:t_list ? join(text, '\n') : '0'
    )
enddef


def Init(): void
    if !kHasPython3
        throw kErrReqPython
    endif
    if !s_vimImported
        exec 'py3 import vim'
        s_vimImported = true
    endif
enddef


export def Exec(a_script: any): void
    Init()
    var script: string = String(a_script)
    exec 'py3' script
enddef


export def Eval(a_script: any): any
    Init()
    var script: string = String(a_script)
    return py3eval(script)
enddef


export def File(fpath: string): void
    Init()
    exec 'py3file' fnameescape(fpath)
enddef


export def Call(funcname: string, ...args: list<any>): any
    Init()
    s_userArgs = args
    py3 __py_args = vim.eval('s_userArgs')
    return py3eval($'{funcname}(*__py_args)')
enddef


#----------------------------------------------------------------------
# system({cmds} [, {cwd} [, {encoding}]])
# {cmds}    : string or list<any>. It's a command when it's a string,
#             and it's [command, ...args] when it's a list
# {cwd}     : the wrok directory
# {encoding}: if specified, try to convert the result
#             from {encoding} to &encoding
#----------------------------------------------------------------------
export def System(a_cmds: any, a_cwd: string = null_string,
        a_encoding: string = null_string): any
    Init()
    var cmd: string = null_string
    var input: string = null_string

    if type(a_cmds) == v:t_string
        cmd = a_cmds
    elseif type(a_cmds) == v:t_list
        cmd = a_cmds[0]
        input = a_cmds[1 :]->join('\n')
    else
        throw $'{{cmds}} should be string or list'
    endif

    var hasInput: bool = input == null_string

    if a_cwd != null
        var cwd: string = getcwd()
        mPath.ChdirNoAutocmd(a_cwd)
        defer () => {
            mPath.ChdirNoAutocmd(cwd)
        }()
    endif

    var res: any = null
    if !mOs.IsWin()
        res = !hasInput ? system(cmd) : system(cmd, input)
        s_shellError = v:shell_error
    else
        py3 import subprocess
        s_userArgs = cmd
        py3 __argv = {'args': vim.eval('s_userArgs')}
        py3 __argv['shell'] = True
        py3 __argv['stdout'] = subprocess.PIPE
        py3 __argv['stderr'] = subprocess.STDOUT
        if hasInput
            py3 __argv['stdin'] = subprocess.PIPE
        endif
        py3 __pp = subprocess.Popen(**__argv)
        if hasInput
            s_userArgs = input
            py3 __si = vim.eval('s_userArgs')
            py3 __pp.stdin.write(__si.encode('utf-8'))
            py3 __pp.stdin.close()
        endif
        py3 __return_text = __pp.stdout.read()
        py3 __return_code = __pp.wait()
        res = Eval('__return_text')
        s_shellError = Eval('__return_code')
    endif

    if a_encoding != null && a_encoding != &encoding
        try
            res = iconv(res, a_encoding, &encoding)
        catch
            mMsg.Error($'failed to convert from {a_encoding} to {&encoding}: {v:exception}')
        endtry
    endif

    return res
enddef
