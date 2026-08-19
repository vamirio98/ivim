vim9script

finish

import autoload 'vc/util/notify.vim' as mn
import autoload 'vc/tui/confirm.vim' as mc

if get(g:, 'vc_notify_rest_loaded', 0)
    finish
endif
g:vc_notify_rest_loaded = 1

# unit: min
const s_defRestInvl = 30
const s_defRestTime = 1

var s_timer: number = -1
var s_restInvl: number = -1


def Rest(a_restTime: number): void
    var restTime = a_restTime * 60
    var restInvl: number = get(g:, 'vcNotifyRestInvl', s_defRestInvl)

    var Cb = (timer) => {
        if restTime <= 0
            timer_stop(timer)
            mn.Info($'Will notify again after {restInvl} min(s)')
            NotifyAfter(restInvl)
            return
        endif
        mn.Info($'Rest {restTime} s...')
        restTime -= 1
    }
    if timer_start(1000, Cb, { repeat: -1 }) < 0
        mn.Error("Can not setup rest timer.")
        NotifyAfter(restInvl)
    endif
enddef

def Notify(_): void
    var restTime = get(g:, 'vcNotifyRestTime', s_defRestTime)
    var choice = mc.Open(
        $"You have been using the computer continously \nfor {s_restInvl} min(s), please rest {restTime} min(s)",
        "&Yes\n&No", 1)

    if choice == 1
        Rest(restTime)
        return
    endif

    NotifyAfter(get(g:, 'vcNotifyRestInvl', s_defRestInvl))
enddef

def NotifyAfter(a_min: number): void
    if s_timer >= 0
        timer_stop(s_timer)
        s_timer = -1
    endif

    if !get(g:, 'vcNotifyRestEn', 1) || a_min <= 0
        return
    endif

    s_restInvl = a_min
    s_timer = timer_start(a_min * 60 * 1000, Notify)
    if s_timer < 0
        mn.Error($"Can not notify after {a_min} min(s)")
    endif
enddef

if get(g:, 'vcNotifyRestEn', 1)
    NotifyAfter(get(g:, 'vcNotifyRestInvl', s_defRestInvl))
endif
