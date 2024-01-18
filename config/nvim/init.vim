call plug#begin('~/.local/share/nvim/plugged')

Plug 'sbdchd/neoformat'
Plug 'NLKNguyen/papercolor-theme'

Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

Plug 'nvim-tree/nvim-tree.lua'

Plug 'neovim/nvim-lspconfig'

Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'

Plug 'nvim-treesitter/nvim-treesitter' ", {'do': ':TSUpdate'}

Plug 'wellle/context.vim'

Plug 'jiangmiao/auto-pairs'

call plug#end()

colorscheme PaperColor

set nocompatible
"set showmatch   "Briefly jump to matching brace
set ignorecase
set mouse=v
set hlsearch
set incsearch
set tabstop=4
set softtabstop=4
set expandtab
set shiftwidth=4
set autoindent
set smarttab
set number
set relativenumber
set wildmode=longest,list
set cc=88
filetype plugin indent on
syntax on
set mouse=a
set clipboard=unnamedplus
filetype plugin on
set cursorline
set ttyfast
set noswapfile
set scrolloff=20
set vb t_vb=

autocmd FileType make set noexpandtab shiftwidth=8 softtabstop=0

autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

"""Below code will format on save
" augroup fmt
"   autocmd!
"   autocmd BufWritePre * undojoin | Neoformat
" augroup END

"""Remap Ctrl+<Left/Right> to tab<p/n>
"set t_Co=256
"let &t_kR = "\e[OC"
"let &t_kL = "\e[OD"
noremap <C-Right> :tabnext<CR>
noremap <C-Left> :tabprevious<CR>
"noremap <Esc>[OD :tabp<CR>
"noremap <Esc>[OC :tabn<CR>

"""Remap Ctrl+<k/j/h/l> to navigate panes
nmap <silent> <c-k> :wincmd k<CR>
nmap <silent> <c-j> :wincmd j<CR>
nmap <silent> <c-h> :wincmd h<CR>
nmap <silent> <c-l> :wincmd l<CR>

noremap <C-f> :Telescope find_files<CR>
noremap <C-l> :NvimTreeToggle<CR>

"""Non-stupid indentation defaults
let g:python_indent = {}
let g:python_indent.closed_paren_align_last_line = v:false
let g:python_indent.open_paren = 'shiftwidth()'
let g:python_indent.continue = 'shiftwidth()'

let g:python3_host_prog = '/projects/libdev_py/users/apriebe/venvs/neovim-venv/bin/python3'
let g:neoformat_enabled_python = ['black']
let g:context_enabled = 1
let g:context_add_mappings = 1
let g:context_add_autocmds = 1
let g:context_max_height = 21
let g:context_max_per_indent = 11
let g:context_skip_regex = '^\s*\($\|#\|//\|/\*\|\*\($\|/s\|\/\)\)'



lua << EOF

-- Linter config
require'lspconfig'.pylsp.setup{
    cmd = { "/projects/libdev_py/users/apriebe/venvs/neovim-venv/bin/pylsp" },
    settings = {
        pylsp = {
            plugins = {
                pylint = { enabled = true, executable = "pylint" },
                pylsp_mypy = { enabled = true },
                jedi_completion = { fuzzy = true }
            }
        }
    },
    flags = {
        debounce_text_changes = 200,
    },
    capabilities = capabilities,
}

-- Linter: Show floating window with linter error on current line
vim.api.nvim_create_autocmd({"CursorHold"}, {
    callback = function()
        local opts = {
            focusable = false,
            close_events = {"BufLeave", "CursorMoved", "InsertEnter", "FocusLost"},
            border = 'rounded',
            source = 'always',
            prefix = ' ',
            scope = 'cursor',
        }
        vim.diagnostic.open_float(nil, opts)
    end
})

-- Show the floating window faster when trigger condition is met
vim.o.updatetime = 1000

-- Linter: Don't show linting messages by default
vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = false,
    update_in_insert = false,
    severity_sort = true,
})

-- nvim-tree: Disable netrw, disable icons, sync tab presence
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
require('nvim-tree').setup({
    renderer = {
        icons = {
            show = {
                file = false,
                folder = false,
                folder_arrow = false,
                git = false,
                modified = false,
                diagnostics = false,
                bookmarks = false,
            }
        }
    },
    tab = {
        sync = {
            open = true,
            close = true
        }
    },
    actions = {
        open_file = {
            window_picker = { enable = false },
        }
    }
})

-- nvim-tree: Bind 't' to open file in new tab
function _G.open_in_tab()
    local lib = require'nvim-tree.lib'
    local node = lib.get_node_at_cursor()
    if node then
        vim.cmd('wincmd p')
        vim.cmd('tabnew ' .. node.absolute_path)
    end
end

vim.api.nvim_set_keymap('n', 't', ':lua open_in_tab()<CR>', {noremap = true, silent = true})

-- LSP: Autocompletion and signature help
local cmp = require'cmp'
cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'nvim_lsp_signature_help' },
    { name = 'vsnip' },
  }, {
    { name = 'buffer' },
  })
})
EOF
