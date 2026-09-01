vim9script

import autoload 'util/str.vim' as mStr


def ParseExpr(a_expr: string): func: string
    # make `expr` a local variable to avoid it be changed in closure
    const expr = mStr.Strip(a_expr)
    if empty(expr)
        throw 'expr is empty'
    endif

    return () => {
        var text = expr->eval()
        return type(text) == v:t_string ? text : string(text)
    }
enddef

# see Button.new to get escape rule
# Note: only support alpha as shortcut
# return: (text/Text(), key, keyPos)
# e.g.:
#   1) [I] 'hello'
#      [O] ('hello', null_string, -1)
#   2) [I] '&hello'
#      [O] ('hello', 'h', 0)
def ParseText(a_text: any): tuple<string, string, number>
    var parts: list<string> = a_text->split('&&')
    var key: string = null_string
    var keypos: number = -1
    var pos: number = 0

    # text properities' `col` is counted by bytes
    var newParts = []
    for part in parts
        var tokens = split(part, '&', 1)
        if len(tokens) == 2
            if empty(tokens[1])
                throw 'an alpha should follow &'
            elseif key != null
                throw 'multi & found'
            endif
            key = tokens[1][0]->tolower()
            keypos = pos + len(tokens[0])
        elseif len(tokens) > 2
            throw 'multi "&" found'
        endif
        newParts->add(tokens->join(''))
        pos += len(part)
    endfor

    var text = newParts->join('&')
    return (text, key, keypos)
enddef


type TextFunc = func: tuple<string, string, number>

export class Button
    var _key: string = null_string  # null means no key
    var _pos: number = -1  # key offset, -1 means not key
    var _text: string = null_string
    var _T: TextFunc = null_function
    var _Cb: func: void = null_function
    var id: number = -1
    var help: string = null_string

    # {desc} has follow key:
    #   text (must): button text, has following specified description:
    #     1) '&x' : 'x' is the shortcut key
    #     2) '&&' : escape '&'
    #   callback (optional, but must exist if a shortcut found):
    #     a function to be ecexute when hit button
    #   help (optional): tip when hover
    # or {desc} can be a list: [text, callback, help]
    def new(a_desc: any)
        if type(a_desc) == v:t_dict
            [this._text, this._key, this._pos] = ParseText(a_desc['text'])
            if this._key != null && !a_desc->has_key('callback')
                throw 'callback is needed when shortcut found'
            endif
            this._Cb = get(a_desc, 'callback', null_function)
            this.help = get(a_desc, 'help', null_string)
        elseif type(a_desc) == v:t_list
            [this._text, this._key, this._pos] = ParseText(a_desc[0])
            if this._key != null && len(a_desc) < 2
                throw 'callback is needed when shortcut found'
            endif
            this._Cb = get(a_desc, 1, null_function)
            this.help = get(a_desc, 2, null_string)
        else
            throw 'invalid param'
        endif
    enddef

    # {Text}: return (text, key, keyPos)
    def newFunc(A_text: TextFunc, A_callback: func: void = null_function,
            help: string = null_string)
        this._T = A_text
        this._Cb = A_callback
        this.help = help
    enddef

    # return: (text, key, keyPos)
    def Content(): tuple<string, string, number>
        if this._T == null
            return (this._text, this._key, this._pos)
        endif
        return this._T()
    enddef

    def Exec(): void
        if this._Cb != null
            this._Cb()
        endif
    enddef

    def SetId(id: number): void
        this.id = id
    enddef
endclass
