vim9script

import autoload 'tool/option.vim' as mOption
import autoload 'util/path.vim' as mPath

type Option = mOption.Option


var lspOpts = {
    # aleSupport: true,
    autoComplete: false,
    autoHighlight: false,
    # autoPopulateDiags: false,
    # completionMatcher: 'fuzzy',
    hoverFallback: false,
    definitionFallback: true,
    omniComplete: true,
    outlineOnRight: true,
    popupBorder: true,
    semanticHighlight: false,
    usePopupInCodeAction: true,
    showDiagWithVirtualText: true,
    diagVirtualTextAlign: 'after',
    diagVirtualTextWrap: 'truncate',
}

var defLspServers = [
    {
        name: 'clangd',
        filetype: ['c', 'cpp'],
        path: 'clangd',
        args: ['--background-index', '--clang-tidy'],
    },
    {
        name: 'gopls',
        filetype: 'go',
        path: 'gopls',
        args: ['serve'],
    },
    {
        name: 'luals',
        filetype: 'lua',
        path: 'lua-language-server',
        args: [],
    },
    {
        name: 'ty',
        filetype: 'python',
        path: 'ty',
        args: ['server'],
    },
    {
        name: 'vimls',
        filetype: ['vim'],
        path: 'vimls',
        args: [],
        initializationOptions: {
            runtimepath: globpath(&runtimepath, '', 0, 1),
        },
    },
]

var lspServers: list<dict<any>> = []
for lsp in defLspServers
    if executable(lsp['path'])
        lspServers->add(lsp)
    endif
endfor


def Hover(): string
    var res: string = execute('LspHover', 'silent')
    return res =~ 'Error' ? 'K' : ''
enddef

# {{{ keymap
def GoToDefinition(): void
    var res: string = execute('LspGotoDefinition')
    if res =~ 'Error'
        exec 'normal! gd'
        clearmatches()
    endif
enddef


def GetInlayHints(): bool
    return g:LspOptionsGet()['showInlayHints']
enddef
def SetInlayHints(on: bool): void
    var opt = g:LspOptionsGet()
    opt.showInlayHints = on
    g:LspOptionsSet(opt)
enddef
var s_inlayHints = Option.new('inlay hints', GetInlayHints, SetInlayHints)

def GetSemanticHighlight(): bool
    return g:LspOptionsGet()['semanticHighlight']
enddef
def SetSemanticHighlight(on: bool): void
    var opt = g:LspOptionsGet()
    opt.semanticHighlight = on
    g:LspOptionsSet(opt)
enddef
var s_semanticHighlight = Option.new('sematic highlight',
    GetSemanticHighlight, SetSemanticHighlight)


def OnLspAttached(): void
    nnoremap <buffer><silent><expr> K Hover()

    nnoremap <buffer> [d <cmd>LspDiag prev<cr>
    nnoremap <buffer> ]d <cmd>LspDiag next<cr>

    nnoremap <buffer> <space>ca <cmd>LspCodeAction<cr>
    nnoremap <buffer> <space>cc <cmd>LspIncomingCalls<cr>
    nnoremap <buffer> <space>cC <cmd>LspOutgoingCalls<cr>
    nnoremap <buffer> <space>cd <cmd>LspDiag show<cr>
    # nnoremap <buffer> <space>cf <cmd>LspFormat<cr>
    nnoremap <buffer> <space>ch <cmd>LspSwitchSourceHeader<cr>
    nnoremap <buffer> <space>cl <cmd>LspCodeLens<cr>
    nnoremap <buffer> <space>co <cmd>LspOutline<cr>
    nnoremap <buffer> <space>cpD <cmd>LspPeekDeclaration<cr>
    nnoremap <buffer> <space>cpd <cmd>LspPeekDefinition<cr>
    nnoremap <buffer> <space>cpi <cmd>LspPeekImpl<cr>
    nnoremap <buffer> <space>cpr <cmd>LspPeekReferences<cr>
    nnoremap <buffer> <space>cr <cmd>LspRename<cr>
    nnoremap <buffer> <space>cy <cmd>LspSubTypeHierarchy<cr>
    nnoremap <buffer> <space>cY <cmd>LspSuperTypeHierarchy<cr>

    nnoremap <buffer> gd <ScriptCmd>GoToDefinition()<cr>
    nnoremap <buffer> gD <cmd>LspGotoDeclaration<cr>
    nnoremap <buffer> gi <cmd>LspGotoImpl<cr>
    nnoremap <buffer> gr <cmd>LspShowReferences<cr>
    nnoremap <buffer> gy <cmd>LspGotoTypeDef<cr>

    nnoremap <buffer> <space>ss <cmd>LspDocumentSymbol<cr>
    nnoremap <buffer> <space>sS <cmd>LspSymbolSearch<cr>

    nnoremap <buffer> <space>uh <ScriptCmd>s_inlayHints.Toggle()<cr>
    nnoremap <buffer> <space>uH <ScriptCmd>s_semanticHighlight.Toggle()<cr>
enddef
# }}}


augroup VcSitePlugLsp
    au!
    au User LspSetup g:LspOptionsSet(lspOpts)
    au User LspSetup g:LspAddServer(lspServers)
    au User LspAttached OnLspAttached()
augroup END
