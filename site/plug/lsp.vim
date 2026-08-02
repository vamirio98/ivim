vim9script

import autoload 'vc/util/keymap.vim'
import autoload 'vc/util/option.vim'
type Option = option.Option

Plug 'yegappan/lsp'

augroup VcSitePlugLsp
  au!
  au User LspSetup g:LspOptionsSet(lspOpts)
  au User LspSetup g:LspAddServer(lspServers)
  au VimEnter * Setup()
augroup END


var lspOpts = {
  # aleSupport: true,
  autoComplete: false,
  autoHighlight: false,
  # autoPopulateDiags: false,
  # completionMatcher: 'fuzzy',
  # hoverFallback: true,
  # definitionFallback: true,
  omniComplete: true,
  outlineOnRight: true,
  popupBorder: true,
  semanticHighlight: true,
  usePopupInCodeAction: true,
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
    name: 'pyright',
    filetype: 'python',
    path: 'pyright-langserver',
    args: ['--stdio'],
    workspaceConfig: {
      python: {
        pythonPath: 'python3',
      },
    },
  },
]

var lspServers: list<dict<any>> = []
for lsp in defLspServers
  if executable(lsp['path'])
    lspServers->add(lsp)
  endif
endfor


def Setup(): void
# {{{ keymap
    var SetGroup = keymap.SetGroup
    var SetDesc = keymap.SetDesc

    def Hover(): string
        var res: string = execute('LspHover', 'silent')
        return res =~ 'Error' ? 'K' : ''
    enddef
    nnoremap <silent><expr> K Hover()

    nnoremap [d <cmd>LspDiag prev<cr>
    nnoremap ]d <cmd>LspDiag next<cr>

    SetGroup('<space>c', 'code')
    nnoremap <space>ca <cmd>LspCodeAction<cr>
    SetDesc('<space>ca', 'Code Action')
    nnoremap <space>cc <cmd>LspIncomingCalls<cr>
    SetDesc('<space>cc', 'Incoming Calls')
    nnoremap <space>cC <cmd>LspOutgoingCalls<cr>
    SetDesc('<space>cC', 'Outgoing Calls')
    nnoremap <space>cd <cmd>LspDiag show<cr>
    SetDesc('<space>cd', 'Show Diag')
    nnoremap <space>cf <cmd>LspFormat<cr>
    SetDesc('<space>cf', 'Format')
    nnoremap <space>ch <cmd>LspSwitchSourceHeader<cr>
    SetDesc('<space>ch', 'Switch Header/Source')
    nnoremap <space>cl <cmd>LspCodeLens<cr>
    SetDesc('<space>cl', 'Code Lens')
    nnoremap <space>co <cmd>LspOutline<cr>
    SetDesc('<space>co', 'Outline')
    SetGroup('<space>cp', 'peek')
    nnoremap <space>cpD <cmd>LspPeekDeclaration<cr>
    SetDesc('<space>cpD', 'Peek Declaration')
    nnoremap <space>cpd <cmd>LspPeekDefinition<cr>
    SetDesc('<space>cpd', 'Peek Definition')
    nnoremap <space>cpi <cmd>LspPeekImpl<cr>
    SetDesc('<space>cpi', 'Peek Impl')
    nnoremap <space>cpr <cmd>LspPeekReferences<cr>
    SetDesc('<space>cpr', 'Peek Refs')
    nnoremap <space>cr <cmd>LspRename<cr>
    SetDesc('<space>cr', 'Rename Symbol')
    nnoremap <space>cy <cmd>LspSubTypeHierarchy<cr>
    SetDesc('<space>cy', 'Show Sub Type Hierarchy')
    nnoremap <space>cY <cmd>LspSuperTypeHierarchy<cr>
    SetDesc('<space>cY', 'Show Super Type Hierarchy')

    SetGroup('g', 'goto')
    def GoToDefinition(): void
        var res: string = execute('LspGotoDefinition')
        if res =~ 'Error'
            exec 'normal! gd'
            clearmatches()
        endif
    enddef
    nnoremap gd <ScriptCmd>GoToDefinition()<cr>
    SetDesc('gd', 'Go to Definition')
    nnoremap gD <cmd>LspGotoDeclaration<cr>
    SetDesc('gD', 'Go to Declaration')
    nnoremap gi <cmd>LspGotoImpl<cr>
    SetDesc('gi', 'Go to Impl')
    nnoremap gr <cmd>LspShowReferences<cr>
    SetDesc('gr', 'Go to Refs')
    nnoremap gy <cmd>LspGotoTypeDef<cr>
    SetDesc('gy', 'Go to Type Define')

    SetGroup('<space>s', 'search')
    nnoremap <space>ss <cmd>LspDocumentSymbol<cr>
    SetDesc('<space>ss', 'Search Symbol (Document)')
    nnoremap <space>sS <cmd>LspSymbolSearch<cr>
    SetDesc('<space>sS', 'Search Symbol (Workspace)')

    def GetInlayHints(): bool
        return g:LspOptionsGet()['showInlayHints']
    enddef
    def SetInlayHints(on: bool): void
        var opt = g:LspOptionsGet()
        opt.showInlayHints = on
        g:LspOptionsSet(opt)
    enddef
    var inlayHints = Option.new('inlay hints', GetInlayHints, SetInlayHints)
    nnoremap <space>uh <ScriptCmd>inlayHints.Toggle()<cr>
    SetDesc('<space>uh', 'Toggle Inlay Hints')

    def GetSemanticHighlight(): bool
        return g:LspOptionsGet()['semanticHighlight']
    enddef
    def SetSemanticHighlight(on: bool): void
        var opt = g:LspOptionsGet()
        opt.semanticHighlight = on
        g:LspOptionsSet(opt)
    enddef
    var semanticHighlight = Option.new('sematic highlight',
        GetSemanticHighlight, SetSemanticHighlight)
    nnoremap <space>uH <ScriptCmd>semanticHighlight.Toggle()<cr>
    SetDesc('<space>uH', 'Toggle Semantic Hightlight')
# }}}
enddef
