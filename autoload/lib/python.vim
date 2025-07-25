vim9script
# only support python3

import autoload "./ui.vim" as ui
import autoload "./platform.vim" as platform

var s_health: string = null_string
var s_ensure: bool = false  # ensure the `vim` module has been import
var s_has_py: bool = true

if !has('python3')
  s_health = 'require +python3 feature'
  s_has_py = false
endif


export var shell_error: number = 0
# in vim9script, vim module in python can only access script level var, not
# function local var, see: https://github.com/vim/vim/issues/8573
var s_args: any = null

#--------------------------------------------------------------
# return if has '+python3'
#--------------------------------------------------------------
export def HasPython(): bool
  return has('python3')
enddef


#--------------------------------------------------------------
# execute code
#--------------------------------------------------------------
export def Exec(script: any): void
  if !s_has_py
    ui.Error(s_health)
    return
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
  if !s_has_py
    ui.Error(s_health)
    return null
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
  if !s_has_py
    ui.Error(s_health)
    return
  endif
  exec 'py3file' fnameescape(filename)
enddef

#--------------------------------------------------------------
# python call
#--------------------------------------------------------------
export def Call(funcname: string, args: any): any
  if !s_has_py
    ui.Error(s_health)
    return null
  endif
  if !s_ensure
    exec 'py3 import vim'
    s_ensure = true
  endif
  s_args = args
  py3 __py_args = vim.eval('args')
  return py3eval(funcname .. '(*__py_args)')
enddef

#----------------------------------------------------------------------
# python system
#----------------------------------------------------------------------
export def System(cmd: string, input: any = null): any
  var has_input: bool = false
  var sinput: string = null_string
  if input != null
    has_input = true
    sinput = type(input) == v:t_string ? input : (
      type(input) == v:t_list ? join(input, '\n') : string(input)
    )
  endif
  if !platform.WIN || !s_has_py
    var text: string = !has_input ? system(cmd) : system(cmd, sinput)
    shell_error = v:shell_error
    return text
  endif
  py3 import subprocess, vim
  s_args = cmd
  py3 __argv = {"args": vim.eval("s_args")}
  py3 __argv["shell"] = True
  py3 __argv["stdout"] = subprocess.PIPE
  py3 __argv["stderr"] = subprocess.STDOUT
  if has_input
    py3 __argv["stdin"] = subprocess.PIPE
  endif
  py3 __pp = subprocess.Popen(**__argv)
  if has_input
    s_args = sinput
    py3 __si = vim.eval("s_args")
    py3 __pp.stdin.write(__si.encode("utf-8"))
    py3 __pp.stdin.close()
  endif
  py3 __return_text = __pp.stdout.read()
  py3 __return_code = __pp.wait()
  shell_error = Eval('__return_code')
  return Eval('__return_text')
enddef
