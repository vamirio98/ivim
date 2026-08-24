vim9script

import autoload 'vc/tui/unit.vim' as mUnit
import autoload 'vc/tui/widget.vim' as mWidget
import autoload 'vc/tui/layout.vim' as mLayout

type Unit = mUnit.Unit
type Widget = mWidget.Widget
type Align = mWidget.Align
type VBox = mLayout.VBox
type HBox = mLayout.HBox

const kSidePad: number = 2  # popup padding between side border and text
const kTopPad: number = 0  # popup padding between top border and text
const kBotPad: number = 0  # popup padding between bottom border and text
const kGroupHintPad: number = 2  # popup padding between group hint and items
const kColPad: number = 1  # popup padding between each column
const kColWidth: number = 20

const kDefIcon: dict<string> = {
    ellipsis: '…',
}

def GetIcon(name: string): string
    if exists('g:whichKeyIcon') && g:whichKeyIcon->has_key(name)
        return g:whichKeyIcon[name]
    endif
    return kDefIcon[name]
enddef

class MainPane extends HBox
    var sidePad: number = kSidePad
    var topPad: number = kTopPad
    var botPad: number = kGroupHintPad
    var colPad: number = kColPad
    var colWidth: number = kColWidth
    var hints: list<any> = null_list

    def new(a_hints: dict<any>)
        this.hints = a_hints->items()->sort(
            (x, y) => x[0] == y[0] ? 0 : (x[0] < y[0] ? -1 : 1)
        )
    enddef

    def Render(): void
        this.width = &columns
        this.height = 0
        var colNum: number = (this.width - 2 * this.sidePad) / this.colWidth
        var itemNumPerCol = (len(this.hints) / colNum)->ceil()->float2nr()
        var ellipsisIcon = GetIcon('ellipsis')
        var maxColWidth = this.colWidth - 2 * this.colPad

        def ShortenText(text: string): string
            if strdisplaywidth(text) <= maxColWidth
                return text
            endif
            return text[: maxColWidth - strdisplaywidth(ellipsisIcon)] ..
                ellipsisIcon
        enddef

        this.widgets = []  # window size may changed, re-caluate
        var offset = 0
        echom $'colNum: {colNum}, itemNumPerCol: {itemNumPerCol}'
        for i in range(colNum)
            if i != 0
                this.AddWidget(Unit.new(' '->repeat(this.colPad)))
            endif

            var colWidget = VBox.new(this)
            offset = i * itemNumPerCol
            for j in range(itemNumPerCol)
                var text: string = this.hints[offset + j]->ShortenText()
                var tmp = Unit.new(text)
                colWidget.AddWidget(tmp)
            endfor
            this.AddWidget(colWidget)
        endfor

        super.Render()
    enddef
endclass

var s_hint: Widget = null_object

export def OpenHint(a_data: dict<any>): void
    var data = deepcopy(a_data)
    var name: string = get(data, 'name', null_string)
    data->filter((key, _) => key != 'name')
    var mainPane = MainPane.new(data)
    mainPane.Render()
    var wid = popup_create(mainPane.image, {})
    popup_hide(wid)
    echom $'{wid}, {len(mainPane.image)}'
enddef
