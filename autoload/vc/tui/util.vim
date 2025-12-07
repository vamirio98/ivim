vim9script

import autoload '../util/string.vim' as str
import autoload '../util/notify.vim'
import autoload '../util/interact.vim'


export def ExtactBorderchars(border: string): list<string>
    if border->len() != 8
        throw $'{border} should include 8 characters'
    endif
    return border->split('\zs')
enddef


export def WinExec(winid: number, command: any, silent: string = null_string): void
    var cmd: string = null_string
    if type(command) == v:t_string
        cmd = command
    elseif type(command) == v:t_list
        cmd = command->join("\n")
    endif
    if command->type() == v:t_string
        keepalt win_execute(winid, cmd, silent)
    endif
enddef


# Parse string. {{{ #
def GenFunc(expr: string): func: string
    # make `expr` a local varialbe to avoid it be changed
    return () => expr->str.Strip()->eval()->string()
enddef

def ParseString(what: string): any
    var tokens: list<any> = []
    var plain: string = ''
    var expr: string = ''
    var inExpr: bool = false

    var whatLen = what->len()
    var i = 0
    while i < whatLen
        var c = what[i]
        if c == '{'
            if inExpr || i + 1 >= whatLen
                throw $'unexpected {{ found in ''{what}'''
            endif
            # enter expr of just a excape '{'
            var nc = what[i + 1]
            if nc == '{'  # excape {
                plain ..= '{'
                i += 1  # skip the next '{'
            elseif nc == '}'  # empty expr
                throw $'empty expr found in ''{what}'''
            else
                inExpr = true
                if !plain->empty()
                    tokens->add(plain)
                endif
                plain = ''
            endif
            i += 1
            continue
        elseif c == '}'
            if inExpr  # leave expr
                # NOTE: use function to generate lambda to avoid the
                # variable captrued (in here it's `expr`) changed in
                # the next loop
                tokens->add(GenFunc(expr))
                expr = ''
                inExpr = false
                i += 1
                continue
            endif
            # if '}' is not the end of a expr, it must occurs in pair
            if i + 1 >= whatLen || what[i + 1] != '}'
                throw $'unexpected }} found in ''{what}'''
            endif
            i += 2  # skip the next '}'
            plain ..= '}'
            continue
        endif

        if inExpr
            expr ..= c
        else
            plain ..= c
        endif
        i += 1
    endwhile

    if inExpr
        throw $'expected }} in end of ''{what}'''
    elseif !plain->empty()
        tokens->add(plain)
    endif

    if tokens->len() == 1 && tokens[0]->type() == v:t_string
        return tokens[0]
    endif

    # combine all tokens into a function which return a string
    return (): string => {
            var res: string = ''
            for Token in tokens
                var t = Token->type()
                if t == v:t_string
                    res ..= Token
                elseif t == v:t_func
                    res ..= Token()
                else
                    res ..= string(Token)
                endif
            endfor
            return res
        }
enddef

#---------------------------------------------------------------
# Parse({what})
# parse expression, all %{} will be treat as expression,
# to excape '%', use '%%'
# {what}: string or list<any>
#   If is a string, support contains expression surround by %{}
#   e.g.:
#     {what} is plain text:
#         [I]: 'hello'
#         [O]: 'hello'
#     {what} contains expression (like vim expr-$', see :h expr-$'):
#         [I]: '{ &lines }'
#         [O]: Result, will be called each time UI render, show
#              lines of current window
#   If is a list, all item in it will be contact each time UI
#   render, all functions will be evaled before contact
#   e.g.:
#       [I]: [ 'hello', '&lines', {funcref} ]
#       [O]: Result, Result() => 'hello60{result of funcref()}'
# return: string if there nothing need to be eval or a function
#---------------------------------------------------------------
export def Parse(what: any): any
    if what->type() == v:t_string
        return ParseString(what)
    elseif what->type() == v:t_list
        var tokens: list<any> = []
        for entry in what
            var t = entry->type()
            if t == v:t_string
                tokens->add(ParseString(entry))
            elseif t == v:t_func
                tokens->add(entry)
            else
                tokens->add(string(entry))
            endif
        endfor

        return () => {
                var res: string = ''
                for Token in tokens
                    res ..= Token->type() == v:t_string ? Token : Token()
                endfor
                return res
            }
    else
        throw $'{what} should be a string or list'
    endif
enddef
# }}} Parse string. #


# Object. {{{ #
# Get tab/global object.
export def Object(tab: bool = false): dict<any>
    if tab
        if !exists('t:_vcTuiObj')
            t:_vcTuiObj = {}
        endif
        return t:_vcTuiObj
    else
        if !exists('g:_vcTuiObj')
            g:_vcTuiObj = {}
        endif
        return g:_vcTuiObj
    endif
enddef

# Get buffer object.
export def BufObj(buf: any): dict<any>
    const kName = '_vcTuiObj'
    var bid: number = type(buf) == v:t_number ? buf : bufnr(buf)
    if !bufexists(bid)
        return null_dict
    endif
    var obj = getbufvar(bid, kName)
    if type(obj) != v:t_dict
        setbufvar(bid, kName, {})
        obj = getbufvar(bid, kName)
    endif
    return obj
enddef
# }}} Object. #


# Keymap. {{{ #
const kKeymap: dict<string> = {
    "\<esc>": 'ESC',
    "\<cr>": 'ENTER',
    "\<space>": 'ENTER',
    "\<up>": 'UP',
    "\<down>": 'DOWN',
    "\<left>": 'LEFT',
    "\<right>": 'RIGHT',
    "\<home>": 'HOME',
    "\<end>": 'END',
    "\<C-j>": 'DOWN',
    "\<C-h>": 'LEFT',
    "\<C-k>": 'UP',
    "\<C-l>": 'RIGHT',
    "\<C-n>": 'NEXT',
    "\<C-p>": 'PREV',
    "\<C-b>": 'PAGEUP',
    "\<C-f>": 'PAGEDOWN',
    "\<C-u>": 'HALFUP',
    "\<C-d>": 'HALFDOWN',
    "\<PageUp>": 'PAGEUP',
    "\<PageDown>": 'PAGEDOWN',
    #"\<C-g>": 'NOHL',
    'j': 'DOWN',
    'k': 'UP',
    'h': 'LEFT',
    'l': 'RIGHT',
    'g': 'TOP',
    'G': 'BOTTOM',
    'q': 'ESC',
    'n': 'NEXT',
    'N': 'PREV',
}

export def Keymap(modifiable: bool = false): dict<string>
    return modifiable ? deepcopy(kKeymap) : kKeymap
enddef
# }}} Keymap. #


# Move and search. {{{ #
export def UpdateCursor(winid: number): void
    const margin: number = &scrolloff
    var winHeight: number = winheight(winid)
    var line: number = line('.', winid)
    var winLine: number = WinScreenLine(winid)
    if winHeight - winLine < margin
        WinExec(winid, $"noautocmd normal {margin - (winHeight - winLine)}\<C-e>")
    elseif winLine - 1 < margin
        WinExec(winid, $"noautocmd normal {margin - (winLine - 1)}\<C-y>")
    endif
enddef

export def MoveCursor(winid: number, offset: string): void
    var winHeight: number = winheight(0)
    var off: number = 0
    if offset == 'PAGEUP'
        off = -winHeight
    elseif offset == 'PAGEDOWN'
        off = winHeight
    elseif offset == 'HALFUP'
        off = -(winHeight / 2)
    elseif offset == 'HALFDOWN'
        off = winHeight / 2
    elseif offset == 'UP'
        off = -1
    elseif offset == 'DOWN'
        off = 1
    elseif offset == 'TOP'
        WinExec(winid, 'noautocmd normal gg')
        return
    elseif offset == 'BOTTOM'
        WinExec(winid, 'noautocmd normal G')
        return
    endif

    if off > 0
        # WinExec(winid, $"noautocmd normal {off}\<C-e>")
        WinExec(winid, $"noautocmd normal {off}j")
    else
        # WinExec(winid, $"noautocmd normal {-off}\<C-y>")
        WinExec(winid, $"noautocmd normal {-off}k")
    endif
enddef


export def SearchOrJump(winid: number, cmd: string): void
    if cmd == '/' || cmd == '?'
        var text: string = interact.Input(cmd)
        # WinExec(winid, 'set hlsearch')
        if text != null_string
            try
                # FIXME: ':' is required or E1050 will occur,
                # vim9script can not distinguish whether '/'
                # is search command or division sign
                WinExec(winid, $':{cmd}{text}')
            catch /^Vim\%((\a\+)\)\=:E486:/
                notify.Error('E486: Pattern not found: ' .. text)
            endtry
            setwinvar(winid, '_vcTuiSearchCmd', cmd)
            setwinvar(winid, '_vcTuiSearchPattern', text)
        endif
    elseif cmd == ':'
        var text: string = interact.Input(cmd)
        if text != null_string
            WinExec(winid, cmd .. text)
        endif
    endif
enddef


export def SearchNext(winid: number, forward: bool): void
    var prevCmd: string = getwinvar(winid, '_vcTuiSearchCmd')
    var prevPat: string = getwinvar(winid, '_vcTuiSearchPattern')
    if prevCmd == null_string || prevPat == null_string
        return
    endif

    var cmd: string = null_string
    if forward
        cmd = prevCmd
    else
        cmd = prevCmd == '/' ? '?' : '/'
    endif
    try
        # FIXME: ':' is required or E1050 will occur,
        # vim9script can not distinguish whether '/'
        # is search command or division sign
        WinExec(winid, $':{cmd}{prevPat}')
    catch /^Vim\%((\a\+)\)\=:E486:/
        notify.Error($'E486: Pattern not found: {prevPat}')
    endtry
enddef
# }}} Move and search. #


# Misc. {{{ #
# Get the cursor position relative to the top row of the screen, one-based.
export def WinScreenLine(winid: number): number
    # Also see :h getwininfo() for more infomation.
    var top: number = line('w0', winid)
    var cur: number = line('.', winid)
    return cur - top + 1
enddef


export def GetWinBufLine(winid: number, lnum: any, end: any = '$'): list<string>
    var bnr: number = winbufnr(winid)
    return getbufline(bnr, lnum, end)
enddef


export def GetWinBufOneLine(winid: number, lnum: any): string
    var bnr: number = winbufnr(winid)
    return getbufoneline(bnr, lnum)
enddef
# }}} Misc. #


# Testing suit. {{{ #
if 1
    import autoload '../util/debug.vim'

    var Equal = debug.Equal
    var Assert = debug.Assert

    def TestParse(): bool
        def CheckExcept(what: string): bool
            var hasExcept: bool = false
            try
                Parse(what)
            catch
                hasExcept = true
                # echom v:exception
            finally
                return hasExcept
            endtry
        enddef

        return Equal('hello', Parse('hello')) &&
            Equal(string(&lines), Parse('{&lines}')()) &&
            Equal('hello ' .. string(&lines), Parse('hello {&lines}')()) &&
            Equal(string(&lines) .. string(&columns),
                        \ Parse('{&lines}{&columns}')()) &&
            Equal('{a}', Parse('{{a}}')) &&
            Assert(CheckExcept('{}')) &&
            Assert(CheckExcept('{')) && Assert(CheckExcept('}')) &&
            Assert(CheckExcept('{&lines}}') && Assert(CheckExcept('{&line{s}'))) &&
            Assert(CheckExcept('{a{&lines}') && Assert(CheckExcept('{&lines}a}')))
    enddef


    def Test(): bool
        return TestParse()
    enddef

    Test()
endif
# }}} Testing suit. #
