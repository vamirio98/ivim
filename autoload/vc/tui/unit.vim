vim9script

import autoload '../util/string.vim' as str

# Parse unit. {{{ #
export class Unit
    public var text: string = null_string
    public var width: number = 0
    var _tokens: list<any> = null_list  # Record all part of text (string or func)
    var key: string = null_string
    var _keyPosDesc: list<number> = null_list  # [whichPart, posInPart]
    public var keyPos: number = -1
    public var hlStart: number = -1
    public var hlEndup: number = -1

    var help: string = null_string
    var _hook: any = null  # Hook triggered when click

    var isSep: bool = false

    public var index: number = -1  # Used for index unit

    #---------------------------------------------------------------
    # new({desc})
    #
    # {desc} can be a string, dict or list
    # string: '&x' means 'x' is the shortcut key, '[x]' means 'x' is a expr
    #         '&&' to escape '&', '[[' to escape '[' and ']]' to escape ']'
    # dict:
    #     what: string, used as above
    #     hook: [optional] any, hook to execute when click unit
    #         - string: like :{hook} in command line
    #         - function: execute the function
    #     help: [optional] string, help text
    # list:
    #     [what, hook, help]
    #---------------------------------------------------------------
    def new(desc: any)
        def ParseHook(hook: any): func
            var ht = type(hook)
            if ht == v:t_string
                return this._GenFunc(hook)
            elseif ht == v:t_func
                return hook
            else
                throw $'desc.hook should be either string or func'
            endif
        enddef

        var dt = type(desc)
        if dt == v:t_string
            [this._tokens, this.key, this._keyPosDesc] = this._Parse(desc)
        elseif dt == v:t_dict
            [this._tokens, this.key, this._keyPosDesc] = this._Parse(desc.what)
            if desc->has_key('hook')
                this._hook = ParseHook(desc.hook)
            endif
            this.help = desc->get('help', null_string)
        elseif dt == v:t_list
            [this._tokens, this.key, this._keyPosDesc] = this._Parse(desc[0])
            if desc->len() > 1
                this._hook = ParseHook(desc[1])
            endif
            this.help = desc->get(2, null_string)
        else
            throw $'unsupported type'
        endif
        this.Update()
    enddef

    def Exec(): void
        if this._hook != null
            var F: func = this._hook
            F()
        endif
    enddef


    # Update `text` and `keyPos`
    def Update(): void
        this.text = ''
        this.width = 0
        this.keyPos = -1

        var i: number = 0
        for Entry in this._tokens
            if this._keyPosDesc != null && i == this._keyPosDesc[0]
                this.keyPos = this.text->len() + this._keyPosDesc[1]
            endif
            this.text ..= type(Entry) == v:t_string ? Entry : Entry()
            i += 1
        endfor
        this.width = strwidth(this.text)
    enddef


    def _GenFunc(expr: string): func: string
        # Make `expr` a local varialbe to avoid it be changed.
        const e: string = expr->str.Strip()
        if e->empty()
            throw $'expr should not be empty'
        endif
        return () => e->eval()->string()
    enddef


    # Return list<[0]: isExpr, [1]: text>
    def _ParseBrackets(text: string): list<list<any>>
        var res: list<any> = []
        var plain: string = ''
        var expr: string = ''
        var inExpr: bool = false

        const textLen: number = text->len()
        var i: number = 0
        while i < textLen
            var c: string = text[i]

            if c == '['
                # Out of bounds
                if i + 1 >= textLen
                    throw $'unexpected [ found in ''{text}'''
                endif

                var nc: string = text[i + 1]
                if inExpr
                    if nc != '['  # Nesting '['
                        throw $'unexpected [ found in ''{text}'''
                    endif
                    expr ..= '['
                    i += 2  # Skip the next '['
                    continue
                elseif nc == '['  # Escape '['
                    plain ..= '['
                    i += 2
                    continue
                elseif nc == ']'  # Empty expr
                    throw $'empty expr found in ''{text}'''
                else
                    inExpr = true
                    if !plain->empty()
                        res->add([false, plain])
                    endif
                    plain = ''
                    i += 1
                    continue
                endif
            elseif c == ']'
                # Check for out of bounds
                var nc: string = null_string
                if i + 1 < textLen
                    nc = text[i + 1]
                endif

                if nc == null
                    if !inExpr
                        throw $'unexpected ] found in ''{text}'''
                    endif
                    # Leave expr
                    res->add([true, expr])
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
                    throw $'unexpected ] found in ''{text}'''
                endif

                # Leave expr
                res->add([true, expr])
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
            throw $'unexpected [ found in ''{text}'''
        elseif !plain->empty()
            res->add([false, plain])
        endif

        return res
    enddef


    # Return: [text,
    #          key(null_string if not found),
    #          keyPos(-1 for not found)]
    def _ParseAnd(isExpr: bool, text: string): list<any>
        var key: string = null_string
        var keyPos: number = -1
        var pos: number = 0

        if isExpr  # No need to conside shortcut key in expr
            return [text->substitute('&&', '&', 'g'), key, keyPos]
        endif

        var tokens = text->split('&&', 1)
        var res: list<string> = []
        for entry in tokens
            var parts: list<string> = entry->split('&', 1)
            if parts->len() == 1
                res->add(parts[0])
                continue
            endif

            if key != null || parts->len() > 2
                throw $'more than one shortcut key found in {text}'
            endif
            if parts[1]->empty()
                throw $'expect key following &'
            endif
            key = parts[1][0]
            keyPos = res->len() + parts[0]->len()
            res->add(parts->join(''))
        endfor

        return [res->join('&'), key, keyPos]
    enddef


    # Return: [tokens, key, keyPosDesc]
    def _ParseText(text: string): list<any>
        var tokens: list<any> = []
        var parts: list<list<any>> = this._ParseBrackets(text)
        var key: string = null_string
        var keyPosDesc: list<number> = null_list

        var i = -1
        for part in parts
            i += 1
            if part[0]  # Expr
                tokens->add(this._GenFunc(part[1]))
                continue
            endif

            var [t: string, k: string, kp: number] =
                this._ParseAnd(part[0], part[1])
            tokens->add(t)
            if k == null
                continue
            endif
            if key != null
                throw $'more than on shortcut key found in {text}'
            endif
            key = k
            keyPosDesc = [i, kp]
        endfor

        return [tokens, key, keyPosDesc]
    enddef


    #---------------------------------------------------------------
    # Parse({what})
    #
    # Parse string and generate Unit.
    # The `[expr]` will be treat as expression, use '[[' to escape '['
    # and ']]' to escape ']'.
    # The `&x` will be treat as shortcut key `x`, use '&&' to escape '&'.
    #
    # {what}: string or list<any>
    #   If is a string, support contains expression surround by %
    #   e.g.:
    #     {what} is plain text:
    #         [I]: 'hello'
    #         [O]: [0]tokens = ['hello']
    #              [1]key = null_string
    #              [2]keyPosDesc = null_list
    #     {what} contains expression (like vim expr-$', but
    #     no need the leading '$' and replace `{` and `}` with `[` and `]`,
    #     see :h expr-$'):
    #         [I]: '&set lines to [&lines]'
    #         [O]: [0]tokens = ['set lines to ', `&lines`]
    #              [1]key = 's'
    #              [2]keyPosDesc = [0, 0]
    #   If is a list, all item in it will be contact each time UI
    #   render, all functions will be evaled before contact
    #   e.g.
    #       [I]: [ 'hel&lo', '[&lines]', {funcref} ]
    #       [O]: [0]tokens = ['hello', `&lines`, {funcref}]
    #            [1]key = 'l'
    #            [2]keyPosDesc = [0, 3]
    #---------------------------------------------------------------
    def _Parse(what: any): list<any>
        if what->type() == v:t_string
            return this._ParseText(what)
        elseif what->type() == v:t_list
            var tokens: list<any> = []
            var key: string = null_string
            var keyPosDesc: list<number> = null_list

            var i = 0
            for entry in what
                var t = entry->type()
                if t == v:t_string
                    var [tt: any, kk: string, kp: list<number>] =
                        this._ParseText(entry)
                    if kk != null
                        if key != null
                            throw $'more than one shortcut key found in ''{what}'''
                        endif
                        key = kk
                        keyPosDesc = [i + kp[0], kp[1]]
                    endif
                    tokens->extend(tt)
                    i += tt->len()
                elseif t == v:t_func
                    tokens->add(entry)
                else
                    tokens->add(string(entry))
                endif
            endfor

            return [tokens, key, keyPosDesc]
        else
            throw $'{what} should be a string or list'
        endif
    enddef
endclass
# }}} Parse unit. #


# Testing suit. {{{ #
if 0
    import autoload '../util/debug.vim'

    var Equal = debug.Equal
    var Assert = debug.Assert

    def TestUnit(): bool
        def CheckExcept(what: string): bool
            var hasExcept: bool = false
            try
                Unit.new(what)
            catch
                hasExcept = true
                # echom v:exception
            finally
                return Assert(hasExcept)
            endtry
        enddef

        def CheckEqual(
                what: any, text: string,
                key: string = null_string, keyPos: number = -1
        ): bool
            var unit: Unit = Unit.new(what)
            return Equal(unit.text, text) && Equal(unit.key, key) &&
                Equal(unit.keyPos, keyPos)
        enddef

        return CheckEqual('hello', 'hello') &&
            CheckEqual('[&lines]', string(&lines)) &&
            CheckEqual('hello [&lines]', $'hello {&lines}') &&
            CheckEqual('[&lines][&columns]', $'{&lines}{&columns}') &&
            CheckEqual('[[a]]', '[a]') &&
                        \
            CheckEqual('&&hello', '&hello') &&
            CheckEqual('&hello', 'hello', 'h', 0) &&
            CheckEqual('&&&hello', '&hello', 'h', 1) &&
                        \
            CheckEqual({what: ['he', 'l&l', 'o', '[&lines]']},
                $'hello{&lines}', 'l', 3) &&
                CheckEqual({what: ['he', 'l&lo[&lines]']},
                $'hello{&lines}', 'l', 3) &&
                        \
            CheckExcept('[]') && CheckExcept('[  ]') &&
            CheckExcept('[') && CheckExcept(']') &&
            CheckExcept('[&lines]]') && CheckExcept('[&line[s]') &&
            CheckExcept('[a[&lines]') && CheckExcept('[&lines]a]') &&
                        \
            CheckExcept('&hel&lo')
    enddef


    def Test(): bool
        return TestUnit()
    enddef

    Test()
endif
# }}} Testing suit. #
