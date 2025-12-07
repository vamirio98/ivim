vim9script
# only support python3

import autoload './os.vim'
import autoload './path.vim'
import autoload './notify.vim'

const errRequirePython: string = 'require +python3 feature'
const hasPython3: bool = has('python3')


export var shellError: number = 0
var hasImportVim: bool = false  # ensure the `vim` module has been import
# in vim9script, vim module in python can only access script level var, not
# function local var, see: https://github.com/vim/vim/issues/8573
var userArgs: any = null

#--------------------------------------------------------------
# return if has '+python3'
#--------------------------------------------------------------
export def HasPython(): bool
    return hasPython3
enddef


#--------------------------------------------------------------
# execute code
#--------------------------------------------------------------
export def Exec(script: any): void
    if !hasPython3
        throw errRequirePython
    endif
    var code: string = type(script) == v:t_string ? script : (
        type(script) == v:t_list ? join(script, '\n') : null_string
    )
    exec 'py3' code
enddef


#--------------------------------------------------------------
# eval script
#--------------------------------------------------------------
export def Eval(script: any): any
    if !hasPython3
        throw errRequirePython
    endif
    var code: string = type(script) == v:t_string ? script : (
        type(script) == v:t_list ? join(script, '\n') : '0'
    )
    return py3eval(code)
enddef


#--------------------------------------------------------------
# py3file
#--------------------------------------------------------------
export def File(filename: string): void
    if !hasPython3
        throw errRequirePython
    endif
    exec 'py3file' fnameescape(filename)
enddef

#--------------------------------------------------------------
# python call
#--------------------------------------------------------------
export def Call(funcname: string, args: any): any
    if !hasPython3
        throw errRequirePython
    endif
    if !hasImportVim
        exec 'py3 import vim'
        hasImportVim = true
    endif
    userArgs = args
    py3 __py_args = vim.eval('userArgs')
    return py3eval(funcname .. '(*__py_args)')
enddef

#----------------------------------------------------------------------
# system({cmds} [, {cwd} [, {encoding}]])
# {cmds}    : string or list<any>. It's a command when it's a string,
#             and it's [command, ...args] when it's a list
# {cwd}     : the wrok directory
# {encoding}: if specified, try to convert the result
#             from {encoding} to &encoding
#----------------------------------------------------------------------
export def System(cmds: any, cwd: string = null_string,
        encoding: string = null_string): any
    if !hasPython3
        throw errRequirePython
    endif

    var cmd: string = null_string
    var input: string = null_string
    var curDir: string = null_string

    if type(cmd) == v:t_string
        cmd = cmds
    elseif type(cmds) == v:t_list
        cmd = cmds[0]
        input = join(cmds[1 :], '\n')
    else
        throw $'{cmds} should be string or list'
    endif

    var hasInput: bool = (input == '')
    var hasCwd: bool = (cwd != null)
    var hasEncoding: bool = (encoding != null)

    if hasCwd
        curDir = getcwd()
        os.ChdirNoAutocmd(cwd)
    endif

    var res: any = null
    if !os.IsWin()
        res = !hasInput ? system(cmd) : system(cmd, input)
        shellError = v:shell_error
    else
        py3 import subprocess, vim
        userArgs = cmd
        py3 __argv = {"args": vim.eval("userArgs")}
        py3 __argv["shell"] = True
        py3 __argv["stdout"] = subprocess.PIPE
        py3 __argv["stderr"] = subprocess.STDOUT
        if hasInput
            py3 __argv["stdin"] = subprocess.PIPE
        endif
        py3 __pp = subprocess.Popen(**__argv)
        if hasInput
            userArgs = input
            py3 __si = vim.eval("userArgs")
            py3 __pp.stdin.write(__si.encode("utf-8"))
            py3 __pp.stdin.close()
        endif
        py3 __return_text = __pp.stdout.read()
        py3 __return_code = __pp.wait()
        shellError = Eval('__return_code')
        res = Eval('__return_text')
    endif

    if hasCwd
        os.ChdirNoAutocmd(curDir)
    endif

    if hasEncoding && encoding != &encoding
        try
            res = iconv(res, encoding, &encoding)
        catch
            notify.Error($'can not convert from {encoding} to {&encoding}: {v:exception}')
        endtry
    endif

    return res
enddef
