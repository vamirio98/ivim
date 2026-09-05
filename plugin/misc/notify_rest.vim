vim9script

import autoload 'util/msg.vim' as mMsg
import autoload 'tui/confirm.vim' as mConfirm

if get(g:, 'vc_notify_rest_loaded', 0)
    finish
endif
g:vc_notify_rest_loaded = 1

# unit: min
const s_defRestInvl = 1
const s_defRestTime = 1

var s_timer: number = -1
var s_restInvl: number = -1


def Rest(a_restTime: number): void
    var restTime = a_restTime * 60
    var restInvl: number = get(g:, 'vcNotifyRestInvl', s_defRestInvl)

    var Cb = (timer) => {
        if restTime <= 0
            timer_stop(timer)
            mMsg.Info($'Will notify again after {restInvl} min(s)')
            NotifyAfter(restInvl)
            return
        endif
        mMsg.Info($'Rest {restTime} s...')
        restTime -= 1
    }
    if timer_start(1000, Cb, { repeat: -1 }) < 0
        mMsg.Error("Can not setup rest timer.")
        NotifyAfter(restInvl)
    endif
enddef

def Notify(_): void
    var restTime = get(g:, 'vcNotifyRestTime', s_defRestTime)
    var choice = mConfirm.Confirm(
        [ 'You have been using the computer continously',
        $'for {s_restInvl} min(s), please rest {restTime} min(s)'],
        [ '&Yes', '&No' ], 1)

    if choice == 1
        Rest(restTime)
        return
    endif

    NotifyAfter(get(g:, 'vcNotifyRestInvl', s_defRestInvl))
    var restInvl: number = get(g:, 'vcNotifyRestInvl', s_defRestInvl)
    mMsg.Info($'Will notify again after {restInvl} min(s)')
enddef

def NotifyAfter(a_min: number): void
    if s_timer >= 0
        timer_stop(s_timer)
        s_timer = -1
    endif

    if !get(g:, 'vcNotifyRestEn', 1)
        return
    endif

    if a_min <= 0
        mMsg.Error('{min} must large than 0')
    endif

    s_restInvl = a_min
    s_timer = timer_start(a_min * 60 * 1000, Notify)
    if s_timer < 0
        mMsg.Error($"failed to setup timer")
    endif
enddef

if get(g:, 'vcNotifyRestEn', 1)
    NotifyAfter(get(g:, 'vcNotifyRestInvl', s_defRestInvl))
endif
