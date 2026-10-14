vim9script


if exists('g:navigatorLoaded')
    finish
endif
g:navigatorLoaded = 1


g:navigator = get(g:, 'navigator', {})
g:navigatorVisual = get(g:, 'navigatorVisual', {})

g:navigatorGroupIcon = get(g:, 'navigatorGroupIcon', '+')
g:navigatorGroupName = get(g:, 'navigatorGroupName', '')  # default group name
g:navigatorGroupSep = get(g:, 'navigatorGroupSep', '/')
g:navigatorSep = get(g:, 'navigatorSep', '')
g:navigatorSpacing = get(g:, 'navigatorSpacing', 3)  # horizontal spaces between items
g:navigatorPadding = get(g:, 'navigatorPadding', [2, 0, 2, 0])  # left, top, right, bottom padding to the window edge
g:navigatorFallback = get(g:, 'navigatorFallback', 0)  # set to 1 to allow fallback to native keymap if key does not exist
# g:navigatorMaxHeight = get(g:, 'navigatorMaxHeight', 20)
# g:navigatorMinHeight = get(g:, 'navigatorMinHeight', 5)
# g:navigatorMaxWidth = get(g:, 'navigatorMaxWidth', 60)
# g:navigatorMinWidth = get(g:, 'navigatorMinWidth', 20)
g:navigatorPopupWidth = get(g:, 'navigatorPopupWidth', 0.6)
g:navigatorPopupHeight = get(g:, 'navigatorPopupHeight', 0.2)
g:navigatorCharIcon = get(g:, 'navigatorCharIcon', {})  # change display char like {"\<bar>": '|', "\<bslash>": '\'}
