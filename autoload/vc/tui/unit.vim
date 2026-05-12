vim9script

import autoload '../util/string.vim' as str
import autoload './widget.vim' as mw

class KeyPosDesc
    public var seq: number = -1  # in which part
    public var pos: number = -1  # position in the part
endclass

type PureWidget = mw.PureWidget
type Widget = mw.Widget
type BaseWidget = mw.BaseWidget
type Align = mw.Align

# one-line widget
export class Unit extends BaseWidget
    # NOTE: colors: [ rowOff, [ [colOff1, colOff2, highlight] ] ]
    # NOTE: 'VcFcKey' is the fake color for the key, and 'VcFcNotKey' is the fake color
    # for others
    var isSep: bool = false
    var key: string = null_string

    public var help: string = null_string
    public var enable: bool = true

    var _parts: list<any> = null_list  # all parts of text (string or func)
    var _keyPosDesc: KeyPosDesc = null_object
    var _Cb: func = null_function  # toggle when click


    #---------------------------------------------------------------
    # new({desc} [, {parent}])
    #
    # {desc} can be a string, dict or list
    # string: '&x' means 'x' is the shortcut key, '[x]' means 'x' is a expr
    #         '&&' to escape '&', '[[' to escape '[' and ']]' to escape ']'
    #         Note: as no hook specified, trigger shortcut will do nothing
    # dict:
    #     what: string, used as above
    #     cb: [optional] any, hook to execute when click unit
    #         - string: like :{hook} in command line
    #         - function: execute the function
    #     help: [optional] string, help text
    # list:
    #     [what, cb, help]
    #     if no need callback, pass it as null
    #---------------------------------------------------------------
    def new(a_desc: any, parent: Widget = null_object)
        this.parent = parent

        def GenCb(cb: any): func: void
            if cb->type() == v:t_string
                return () => {
                    execute cb
                }
            else
                return cb
            endif
        enddef

        var desc: dict<any> = {}

        var t = type(a_desc)
        if t == v:t_string
            desc.what = a_desc
        elseif t == v:t_dict
            desc = a_desc->deepcopy()
        elseif t == v:t_list
            desc.what = a_desc[0]
            desc.cb = a_desc->get(1, null)
            desc.help = a_desc->get(2, null_string)
        else
            throw $'unsupport type: {t}'
        endif

        if type(desc.what) == v:t_string && desc.what =~ '^-\+$'
            this.isSep = true
            return
        endif

        var key = null_string
        [this._parts, this.key, this._keyPosDesc] = this._Parse(desc.what)
        if desc->has_key('cb')
            this._Cb = GenCb(desc.cb)
        endif
        this.help = desc->get('help', null_string)
        this.Update()
        this.Render()
    enddef


    def Exec(): void
        if this._Cb != null
            this._Cb()
        endif
    enddef


    # Re-execute _parts, then update image and colors
    # NOTE: Unit is one-line Widget
    def Update(): void
        var text = ''
        var colorStart = 0

        this.colors = this.key == null ? {} : { 0: [] }
        var i = 0
        for Entry in this._parts
            if this.key != null && i == this._keyPosDesc.seq
                var keyOff = text->strdisplaywidth() + this._keyPosDesc.pos
                if keyOff != 0
                    this.colors[0]->add([0, keyOff, 'VcFcNotKey'])
                endif
                this.colors[0]->add([keyOff, keyOff + 1, 'VcFcKey'])
                colorStart = keyOff + 1
            endif
            text ..= type(Entry) == v:t_string ? Entry : Entry()
            i += 1
        endfor
        this.image = [text]
        this.dispWidth = text->strdisplaywidth()
        this.dispHeight = 1
        if !this.colors->empty()
            this.colors[0]->add([colorStart, this.dispWidth, 'VcFcNotKey'])
        endif

        this.SetDirty()
    enddef


    def _GenFunc(a_expr: string): func: string
        # make `expr` a local variable to avoid it be change in closure
        const expr = a_expr->str.Strip()
        if expr->empty()
            throw 'expr can not be empty'
        endif
        return () => expr->eval()->string()
    enddef


    # Parse item {{{ #
    #---------------------------------------------------------------
    # _Parse({what})
    #
    # Parse string and generate Unit.
    # The `[expr]` will be treat as expression, use '[[' to escape '['
    # and ']]' to escape ']'.
    # The `&x` will be treat as shortcut key `x`, use '&&' to escape '&'.
    #
    # {what}: string or list<any>
    #   If is a string, support contains expression surround by `[]`
    #   e.g.:
    #     {what} is plain text:
    #         [I]: 'hello'
    #         [O]: [0]parts = ['hello']
    #              [1]key = null_string
    #              [2]keyPosDesc = null_object
    #     {what} contains expression (like vim expr-$', but
    #     no need the leading '$' and replace `{` and `}` with `[` and `]`,
    #     see :h expr-$'):
    #         [I]: '&set lines to [&lines]'
    #         [O]: [0]parts = ['set lines to ', `&lines`]
    #              [1]key = 's'
    #              [2]keyPosDesc = { .seq = 0, .pos = 0 }
    #   If is a list, all item in it will be contact each time UI
    #   render, all functions will be evaled before contact
    #   e.g.
    #       [I]: [ 'hel&lo', '[&lines]', {funcref} ]
    #       [O]: [0]parts = ['hello', `&lines`, {funcref}]
    #            [1]key = 'l'
    #            [2]keyPos = { .seq = 0, .pos = 3 }
    #
    # Return: [parts, key, keyPosDesc]
    #---------------------------------------------------------------
    def _Parse(what: any): list<any>
        var t = type(what)
        if t == v:t_string
            return this._DoParse(what)
        elseif t == v:t_list
            var parts: list<any> = []
            var key = null_string
            var keyPosDesc = null_object

            var i = 0
            for entry in what
                var et = type(entry)
                if et == v:t_string
                    var [tmp: list<any>, k: string, kpd: KeyPosDesc] =
                        this._DoParse(entry)
                    if k != null
                        if key != null
                            throw $"more than one shortcut key found in '{what}'"
                        endif
                        key = k
                        keyPosDesc = KeyPosDesc.new(i + kpd.seq, kpd.pos)
                    endif
                    parts->extend(tmp)
                    i += len(tmp)
                elseif et == v:t_func
                    parts->add(entry)
                else
                    parts->add(string(entry))
                endif
            endfor

            return [parts, key, keyPosDesc]
        else
            throw $"'{what}' should be a string or list"
        endif
    enddef

    # Return list<[0]: isExpr: bool, [1]: content: string|func>
    def _EscapeBrackets(text: string): list<list<any>>
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
    #          keyOff(-1 for not found)]
    def _ParseAnd(text: string): list<any>
        var key: string = null_string
        var keyOff: number = -1

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
            keyOff = res->len() + parts[0]->len()
            res->add(parts->join(''))
        endfor

        return [res->join('&'), key, keyOff]
    enddef


    # Return: [parts, key, keyPosDesc]
    def _DoParse(text: string): list<any>
        var parts: list<any> = []
        var tokens: list<list<any>> = this._EscapeBrackets(text)
        var key: string = null_string
        var keyPosDesc: KeyPosDesc = null_object

        var i = 0
        for token in tokens
            if token[0]  # Expr
                parts->add(this._GenFunc(token[1]))
                continue
            endif

            var [t: string, k: string, ko: number] =
                this._ParseAnd(token[1])
            parts->add(t)
            if k == null
                continue
            endif
            if key != null
                throw $'more than on shortcut key found in {text}'
            endif
            key = k
            keyPosDesc = KeyPosDesc.new(i, ko)

            i += 1
        endfor

        return [parts, key, keyPosDesc]
    enddef
    # }}} Parse item #

    def Render(): void
        if !this.dirty
            return
        endif

        [this.image, this.colors] = mw.Compose(this)
        this.dispWidth = this.image->len() == 0 ? 0 : this.image[0]->len()
        this.dispHeight = this.image->len()
        this.dirty = false
    enddef
endclass


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
                key: string = null_string, keyOff: number = -1
        ): bool
            var unit: Unit = Unit.new(what)
            unit.SetAlign(Align.Left)
            unit.Render()

            def CheckKeyOff(colors: dict<list<list<any>>>,
                    ko: number = -1): bool
                if colors->empty()
                    return false
                endif

                for c in colors[0]
                    if c[2] == 'VcFcKey'
                        return c[0] == ko && c[1] == ko + 1
                    endif
                endfor
                return false
            enddef

            return Equal(unit.image[0], text) &&
                (key == null || ( Equal(unit.key, key) &&
                Assert(CheckKeyOff(unit.colors, keyOff)) ))
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
