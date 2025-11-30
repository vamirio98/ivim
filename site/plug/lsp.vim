vim9script

import autoload '../../autoload/module/keymap.vim' as keymap
import autoload '../../autoload/module/option.vim' as option
type Option = option.Option

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

SetGroup('<leader>c', 'code')
nnoremap <leader>ca <cmd>LspCodeAction<cr>
SetDesc('<leader>ca', 'Code Action')
nnoremap <leader>cc <cmd>LspIncomingCalls<cr>
SetDesc('<leader>cc', 'Incoming Calls')
nnoremap <leader>cC <cmd>LspOutgoingCalls<cr>
SetDesc('<leader>cC', 'Outgoing Calls')
nnoremap <leader>cd <cmd>LspDiag show<cr>
SetDesc('<leader>cd', 'Show Diag')
nnoremap <leader>cf <cmd>LspFormat<cr>
SetDesc('<leader>cf', 'Format')
nnoremap <leader>ch <cmd>LspSwitchSourceHeader<cr>
SetDesc('<leader>ch', 'Switch Header/Source')
nnoremap <leader>cl <cmd>LspCodeLens<cr>
SetDesc('<leader>cl', 'Code Lens')
nnoremap <leader>co <cmd>LspOutline<cr>
SetDesc('<leader>co', 'Outline')
SetGroup('<leader>cp', 'peek')
nnoremap <leader>cpD <cmd>LspPeekDeclaration<cr>
SetDesc('<leader>cpD', 'Peek Declaration')
nnoremap <leader>cpd <cmd>LspPeekDefinition<cr>
SetDesc('<leader>cpd', 'Peek Definition')
nnoremap <leader>cpi <cmd>LspPeekImpl<cr>
SetDesc('<leader>cpi', 'Peek Impl')
nnoremap <leader>cpr <cmd>LspPeekReferences<cr>
SetDesc('<leader>cpr', 'Peek Refs')
nnoremap <leader>cr <cmd>LspRename<cr>
SetDesc('<leader>cr', 'Rename Symbol')
nnoremap <leader>cy <cmd>LspSubTypeHierarchy<cr>
SetDesc('<leader>cy', 'Show Sub Type Hierarchy')
nnoremap <leader>cY <cmd>LspSuperTypeHierarchy<cr>
SetDesc('<leader>cY', 'Show Super Type Hierarchy')

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

SetGroup('<leader>s', 'search')
nnoremap <leader>ss <cmd>LspDocumentSymbol<cr>
SetDesc('<leader>ss', 'Search Symbol (Document)')
nnoremap <leader>sS <cmd>LspSymbolSearch<cr>
SetDesc('<leader>sS', 'Search Symbol (Workspace)')

def GetInlayHints(): bool
  return g:LspOptionsGet()['showInlayHints']
enddef
def SetInlayHints(on: bool): void
  var opt = g:LspOptionsGet()
  opt.showInlayHints = on
  g:LspOptionsSet(opt)
enddef
var inlayHints = Option.new('inlay hints', GetInlayHints, SetInlayHints)
nnoremap <leader>uh <ScriptCmd>inlayHints.Toggle()<cr>
SetDesc('<leader>uh', 'Toggle Inlay Hints')

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
nnoremap <leader>uH <ScriptCmd>semanticHighlight.Toggle()<cr>
SetDesc('<leader>uH', 'Toggle Semantic Hightlight')

# }}}

var defaultLspServers = [
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
for lsp in defaultLspServers
  if executable(lsp['path'])
    lspServers->add(lsp)
  endif
endfor

augroup ivim_lsp
  au!
  au User LspSetup g:LspOptionsSet(lspOpts)
  au User LspSetup g:LspAddServer(lspServers)
augroup END
