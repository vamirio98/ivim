vim9script

import autoload 'util/msg.vim' as mMsg

type GetFunc = func(): any
type SetFunc = func(bool): void
type ToggleFunc = func(): void

export class Option
    var Get: GetFunc = null_function
    var Set: SetFunc = null_function
    var on: any = null
    var off: any = null
    var Toggle: ToggleFunc = null_function

    static def _GenGet(name: string): GetFunc
        return (): any => eval($'&{name}')
    enddef

    static def _GenSet(name: string, opt: Option): SetFunc
        return (on: bool): void => {
            if opt.on == null
                exec $'setlocal {on ? '' : 'no'}{name}'
            else
                exec $'setlocal {name}={type(opt.on) == v:t_string ? opt.on : string(opt.on)}'
            endif
        }
    enddef

    static def _GenToggle(name: string, opt: Option): ToggleFunc
        return (): void => {
            if opt.on == null
                opt.Set(!opt.Get())
                if opt.Get()
                    mMsg.Info($'enable {name}')
                else
                    mMsg.Warn($'disable {name}')
                endif
            else
                var status = opt.Get()
                exec $'setlocal {name}={status == opt.on ? opt.off : opt.on}'
                status = opt.Get()
                if status == opt.on
                    mMsg.Info($'set {name} = {status}')
                else
                    mMsg.Warn($'set {name} = {status}')
                endif
            endif
        }
    enddef


    def new(name: string, this.Get = v:none, this.Set = v:none,
            this.on = v:none, this.off = v:none)
        if this.Get == null
            this.Get = _GenGet(name)

        endif
        if this.Set == null
            this.Set = _GenSet(name, this)
        endif
        this.Toggle = _GenToggle(name, this)
    enddef

    def newOnOff(name: string, this.on, this.off)
        this.Get = _GenGet(name)
        this.Set = _GenSet(name, this)
        this.Toggle = _GenToggle(name, this)
    enddef
endclass
