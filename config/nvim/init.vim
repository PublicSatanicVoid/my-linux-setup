call plug#begin('~/.local/share/nvim/plugged')

Plug 'sainnhe/everforest'
"Plug 'sainnhe/sonokai'
Plug 'EdenEast/nightfox.nvim'
"Plug 'rose-pine/neovim'

"Plug 'sbdchd/neoformat'
Plug 'xiyaowong/transparent.nvim'

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

Plug 'ojroques/vim-oscyank'

Plug 'f-person/git-blame.nvim'

call plug#end()



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" COLOR SCHEME
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"au ColorScheme * hi Normal ctermbg=none guibg=none
"au ColorScheme myspecialcolors hi Normal ctermbg=red guibg=red

let g:sonokai_style = 'shusia'
let g:sonokai_disable_italic_comment = 1
let g:sonokai_enable_italic = 0
let g:sonokai_better_performance = 1
let g:sonokai_transparent_background = 2
"colorscheme sonokai

let g:everforest_background = 'hard'
let g:everforest_better_performance = 1
let g:everforest_disable_italic_comment = 1
let g:everforest_enable_italic = 0
let g:everforest_transparent_background = 2
let g:everforest_ui_contrast = 'low'
colorscheme everforest

lua << EOF
require("rose-pine").setup({
    variant = "main",
    dark_variant = "main",
    styles = {
        bold = true,
        italic = false,
        transparency = true,
    }
})
EOF
"colorscheme rose-pine

"colorscheme nightfox
"colorscheme nordfox     "Good for darker backgrounds
"colorscheme duskfox



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" VIM OPTIONS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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
"set autoindent
set smartindent
"set smarttab
set number
set relativenumber
set wildmode=longest,list
set cc=89
set textwidth=89
filetype plugin indent on
syntax on
set mouse=a
set clipboard=unnamedplus
filetype plugin on
set cursorline
set ttyfast
set noswapfile
set scrolloff=10
set vb t_vb=
set t_Co=256  "What does this do

autocmd FileType make set noexpandtab shiftwidth=8 softtabstop=0

"""Not sure what this does, commenting it out for now
"autocmd BufReadPost *
"    \ if line("'\"") > 0 && line("'\"") <= line("$") |
"    \   exe "normal! g`\"" |
"    \ endif

"""Below code will format on save
"autocmd BufWritePre * lua vim.lsp.buf.format()



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" KEY MAPPINGS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""Remap Ctrl+<Left/Right> to tab<p/n>
noremap <C-Right> :tabnext<CR>
noremap <C-Left> :tabprevious<CR>

"""Remap Shift+<k/j/h/l> to navigate panes
nmap <S-Up> :wincmd k<CR>
nmap <S-Down> :wincmd j<CR>
nmap <S-Left> :wincmd h<CR>
nmap <S-Right> :wincmd l<CR>

nnoremap <C-f> :Telescope find_files<CR>
nnoremap <S-f> :Telescope live_grep<CR>
nnoremap <C-l> :NvimTreeToggle<CR>

"nnoremap / :%s%
nnoremap / :%s###gn<Left><Left><Left><Left>

"<space>y to copy text to system clipboard
vmap <space>y <Plug>OSCYankVisual
nmap <space>y <Plug>OSCYankVisual

" Go to definition in new tab
nnoremap <C-w>gd <C-w><C-]><C-w>T



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" PLUGIN SETUP
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""Non-stupid indentation defaults
let g:python_indent = {}
let g:python_indent.closed_paren_align_last_line = v:false
let g:python_indent.open_paren = 'shiftwidth()'
let g:python_indent.continue = 'shiftwidth()'

let g:python3_host_prog = $NEOVIM_VENV . '/bin/python3'
"let g:neoformat_enabled_python = ['black']
let g:context_enabled = 1
let g:context_add_mappings = 1
let g:context_add_autocmds = 1
let g:context_max_height = 21
let g:context_max_per_indent = 11
let g:context_skip_regex = '^\s*\($\|#\|//\|/\*\|\*\($\|/s\|\/\)\)'

let g:gitblame_display_virtual_text = 1
let g:gitblame_enabled = 0  "Disable by default; can toggle with :GitBlameToggle
let g:gitblame_date_format = '%r'
let g:gitblame_message_template = '    <author>, <date> • [<sha>] <summary>'

command! BlameOn :GitBlameEnable
command! BlameOff :GitBlameDisable
command! Blame :GitBlameToggle

lua << EOF

local neovim_venv = os.getenv("NEOVIM_VENV") or "~/venvs/neovim_venv"

-- Linter config
require'lspconfig'.pylsp.setup{
    cmd = { neovim_venv .. "/bin/pylsp" },
    settings = {
        pylsp = {
            plugins = {
                -- pylint = { enabled = true, executable = "pylint" },
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

-- Linter config
local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap=true, silent=true, buffer=bufnr }
    --vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    --vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    --vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
end

--Below was causing problems with standalong Python files.
-- local configs = require 'lspconfig.configs'
-- if not configs.ruff_lsp then
--     configs.ruff_lsp = {
--         default_config = {
--             cmd = { 'ruff-lsp' },
--             filetypes = { 'python' },
--             root_dir = require('lspconfig').util.find_git_ancestor,
--             init_options = {
--                 settings = {
--                     args = {}
--                 }
--             }
--         }
--     }
-- end

require('lspconfig').ruff_lsp.setup {
    cmd = { neovim_venv .. "/bin/ruff-lsp" },
    on_attach = on_attach,
    init_options = {
        settings = {
            -- Any extra CLI arguments for `ruff` go here.
            args = {},
        }
    }
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

-- Linter: Configure display of linting messages in-line
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
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
                file = true,
                folder = true,
                folder_arrow = true,
                git = true,
                modified = true,
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

-- Telescope: Let 't' open file in new tab, not just <C-t>
require'telescope'.setup({
    pickers = {
        find_files = {
            mappings = {
                n = {
                    -- Do "Esc" to exit insert mode in Telescope, then "t"
                    ["t"] = "select_tab",
                }
            }
        },
        live_grep = {
            mappings = {
                n = {
                    -- Do "Esc" to exit insert mode in Telescope, then "t"
                    ["t"] = "select_tab",
                }
            }
        }
    }
})

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

