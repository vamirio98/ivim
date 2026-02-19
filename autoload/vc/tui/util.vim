vim9script

import autoload '../util/string.vim' as str


# Parse item. {{{ #
export class Item
    var _text: any
    var shortcut: string

    def new(what: any)
        [this._text, this.shortcut] = this._Parse(what)
    enddef

    def Text(): string
        if type(this._text) == v:t_string
            return this._text
        else
            var F: func = this._text
            return F()
        endif
    enddef


    def _GenFunc(expr: string): func: string
        # Make `expr` a local varialbe to avoid it be changed.
        const e: string = expr->str.Strip()
        if e->empty()
            throw $'expr should not be empty'
        endif
        return () => e->eval()->string()
    enddef

    # Return: [_text, shortcut]
    def _ParseString(what: string): list<any>
        var tokens: list<any> = []
        var plain: string = ''
        var expr: string = ''
        var inExpr: bool = false
        var Text: any
        var shortcut: string = null_string

        var whatLen = what->len()
        var i = 0
        while i < whatLen
            var c: string = what[i]

            if c == '&'
                # Out of bounds
                if i + 1 >= whatLen
                    throw $'unexpected & found in ''{what}'''
                endif
                var nc: string = what[i + 1]
                if nc == '&'  # Escape '&'
                    if inExpr
                        expr ..= '&'
                    else
                        plain ..= '&'
                    endif
                    i += 2  # Skip the next '&'
                    continue
                endif
                # Shortcut always in plain part
                if inExpr
                    expr ..= '&'
                    i += 1
                    continue
                else
                    if shortcut != null
                        throw $'only one shortcut shound be found in ''{what}'''
                    endif
                    shortcut = nc
                    i += 1  # Hide the '&'
                    continue
                endif
            endif

            if c == '['
                # Out of bounds
                if i + 1 >= whatLen
                    throw $'unexpected [ found in ''{what}'''
                endif

                var nc: string = what[i + 1]
                if inExpr
                    if nc != '['  # Nesting '['
                        throw $'unexpected [ found in ''{what}'''
                    endif
                    expr ..= '['
                    i += 2  # Skip the next '['
                    continue
                elseif nc == '['  # Escape '['
                    plain ..= '['
                    i += 2  # Skip the next '['
                    continue
                elseif nc == ']'  # Empty expr
                    throw $'empty expr found in ''{what}'''
                else
                    inExpr = true
                    if !plain->empty()
                        tokens->add(plain)
                    endif
                    plain = ''
                    i += 1
                    continue
                endif
            elseif c == ']'
                # Check for out of bounds
                var nc: string = null_string
                if i + 1 < whatLen
                    nc = what[i + 1]
                endif

                if nc == null
                    if !inExpr
                        throw $'unexpected ] found in ''{what}'''
                    endif
                    # Leave expr
                    # NOTE: use function to generate lambda to avoid the
                    # variable captrued (in here it's `expr`) changed in
                    # the next loop
                    tokens->add(this._GenFunc(expr))
                    expr = ''
                    inExpr = false
                    i += 1
                    continue
                endif

                if nc == ']'  # Escape ']'
                    if inExpr
                        expr ..= ']'
                    else
                        plain ..= ']'
                    endif
                    i += 2  # Skip the next ']'
                    continue
                endif

                if !inExpr
                    throw $'unexpected ] found in ''{what}'''
                endif

                # Leave expr
                # NOTE: use function to generate lambda to avoid the
                # variable captrued (in here it's `expr`) changed in
                # the next loop
                tokens->add(this._GenFunc(expr))
                expr = ''
                inExpr = false
                i += 1
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
            throw $'expected ] in end of ''{what}'''
        elseif !plain->empty()
            tokens->add(plain)
        endif

        if tokens->len() == 1 && tokens[0]->type() == v:t_string
            Text = tokens[0]
        else
            # Combine all tokens into a function which return a string
            Text = (): string => {
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
        endif

        return [Text, shortcut]
    enddef

    #---------------------------------------------------------------
    # Parse({what})
    #
    # Parse string and generate Item.
    # The `[expr]` will be treat as expression, use '[[' to escape '['
    # and ']]' to escape ']'.
    # The `&x` will be treat as shortcut `x`, use '&&' to escape '&'.
    #
    # {what}: string or list<any>
    #   If is a string, support contains expression surround by %
    #   e.g.:
    #     {what} is plain text:
    #         [I]: 'hello'
    #         [O]: [0]Text() => 'hello'
    #              [1]shortcut = null_string
    #     {what} contains expression (like vim expr-$', but
    #     no need the leading '$' and replace `{` and `}` with `[` and `]`,
    #     see :h expr-$'):
    #         [I]: '&set lines to [&lines]'
    #         [O]: [0]Text() => will be called each time
    #              UI render, show the lines of current window.
    #              [1]shortcut = 's'
    #   If is a list, all item in it will be contact each time UI
    #   render, all functions will be evaled before contact
    #   e.g.(`&lines` = 60):
    #       [I]: [ '&hello', '[&lines]', {funcref} ]
    #       [O]: [0]Text() => 'hello60{result of funcref()}'
    #            [1]shortcut = 'h'
    #---------------------------------------------------------------
    def _Parse(what: any): list<any>
        if what->type() == v:t_string
            return this._ParseString(what)
        elseif what->type() == v:t_list
            var tokens: list<any> = []
            var Text: any
            var shortcut: string = null_string
            var hasShortcut: bool = false

            for entry in what
                var t = entry->type()
                if t == v:t_string
                    var [tt: any, ss: string] = this._ParseString(entry)
                    if ss != null
                        if hasShortcut
                            throw $'more than one shortcut found in ''{what}'''
                        endif
                        hasShortcut = true
                        shortcut = ss
                    endif
                    tokens->add(tt)
                elseif t == v:t_func
                    tokens->add(entry)
                else
                    tokens->add(string(entry))
                endif
            endfor

            Text = () => {
                    var res: string = ''
                    for Token in tokens
                        res ..= Token->type() == v:t_string ? Token : Token()
                    endfor
                    return res
                }

            return [Text, shortcut]
        else
            throw $'{what} should be a string or list'
        endif
    enddef
endclass
# }}} Parse item. #


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


# String. {{{ #
# Remove all tailing '\t\r\n ' in string list.
export def StrListNormalize(textlist: any): list<string>
    var tl: list<string>
    if type(textlist) == v:t_list
        tl = textlist
    else
        tl = string(textlist)->split("\n", 1)
    endif

    var res: list<string> = []
    for text in tl
        var tmp = text->str.Rstrip()
        res->add(tmp)
    endfor

    return res
enddef
# }}} String. #


# Testing suit. {{{ #
if 0
    import autoload '../util/debug.vim'

    var Equal = debug.Equal
    var Assert = debug.Assert

    def TestItem(): bool
        def CheckExcept(what: string): bool
            var hasExcept: bool = false
            try
                Item.new(what)
            catch
                hasExcept = true
                # echom v:exception
            finally
                return Assert(hasExcept)
            endtry
        enddef

        def CheckEqual(
                what: any, text: string, shortcut: string = null_string
        ): bool
            var item: Item = Item.new(what)
            return Equal(item.Text(), text) && Equal(item.shortcut, shortcut)
        enddef

        return CheckEqual('hello', 'hello') &&
            CheckEqual('[&lines]', string(&lines)) &&
            CheckEqual('hello [&lines]', $'hello {&lines}') &&
            CheckEqual('[&lines][&columns]', $'{&lines}{&columns}') &&
            CheckEqual('[[a]]', '[a]') &&
                        \
            CheckEqual('&&hello', '&hello') &&
            CheckEqual('&hello', 'hello', 'h') &&
            CheckEqual('&&&hello', '&hello', 'h') &&
                        \
            CheckEqual(['he', 'l&l', 'o', '[&lines]'], $'hello{&lines}', 'l') &&
                        \
            CheckExcept('[]') && CheckExcept('[  ]') &&
            CheckExcept('[') && CheckExcept(']') &&
            CheckExcept('[&lines]]') && CheckExcept('[&line[s]') &&
            CheckExcept('[a[&lines]') && CheckExcept('[&lines]a]') &&
                        \
            CheckExcept('&hel&lo')
    enddef


    def Test(): bool
        return TestItem()
    enddef

    Test()
endif
# }}} Testing suit. #
