local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    "sainnhe/everforest",
--    "EdenEast/nightfox.nvim",
--    "rose-pine/neovim",
    "xiyaowong/transparent.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "mihaifm/bufstop",
    "nvim-tree/nvim-tree.lua",
    "neovim/nvim-lspconfig",
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
--    "hrsh7th/vim-vsnip",
--    "hrsh7th/cmp-vsnip",
--    "hrsh7th/vim-vsnip-integ",
    "hrsh7th/cmp-nvim-lsp-signature-help",
    "nvim-treesitter/nvim-treesitter",
    "wellle/context.vim",
    "jiangmiao/auto-pairs",
    "ojroques/vim-oscyank",
    "f-person/git-blame.nvim",
    {"ThePrimeagen/harpoon", branch = "harpoon2"},
})

vim.g.everforest_background = "hard"
vim.g.everforest_better_performance = 1
vim.g.everforest_disable_italic_comment = 1
vim.g.everforest_enable_italic = 0
vim.g.everforest_transparent_background = 2
vim.g.everforest_ui_contrast = "low"
vim.cmd.colorscheme "everforest"

vim.opt.encoding = "utf-8"
vim.opt.cursorline = false
vim.opt.compatible = false
vim.opt.ignorecase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.cmd [[
    filetype plugin on
    filetype plugin indent on
]]
vim.opt.autoindent = true --Not sure about this one, TODO
vim.opt.smartindent = true
vim.opt.number = true
vim.opt.relativenumber = true
--vim.opt.wildmode = {"longest", "list"}  --is that how you do this?
vim.opt.colorcolumn = "89"
vim.opt.textwidth = 89
--filetype plugin indent on  --how to do this in lua?
--filetype plugin on  --how to do this in lua?
vim.opt.ttyfast = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
vim.opt.scrolloff = 10
--set vb t_vb=  --how to do this in lua?

--autocmd FileType make set noexpandtab shiftwidth=8 softtabstop=0


function nmap(shortcut, command)
    vim.api.nvim_set_keymap('n', shortcut, command, { noremap = true, silent = false })
end

function tmap(shortcut, command)
    vim.api.nvim_set_keymap('t', shortcut, command, { noremap = true, silent = false  })
end

function vmap(shortcut, command)
    vim.api.nvim_set_keymap('v', shortcut, command, { noremap = true, silent = false  })
end

nmap("<C-Right>", "<cmd>tabnext<CR>")
nmap("<C-Left>", "<cmd>tabprevious<CR>")
--TODOmaybe, S-<up/down/left-right> for panes
nmap("<C-f>", "<cmd>Telescope find_files<CR>")
nmap("<S-f>", "<cmd>Telescope live_grep<CR>")
nmap("<C-l>", "<cmd>NvimTreeToggle<CR>")
nmap("/", ":%s###gn<Left><Left><Left><Left>")
vmap("<space>y", "<Plug>OSCYankVisual")
nmap("<space>y", "<Plug>OSCYankVisual")
nmap("<space>b", "<cmd>BufstopFast<CR>")
nmap("<space>n", "<cmd>bprev<CR>")
nmap("<space>p", "<cmd>bnext<CR>")
tmap("<esc>", "<C-\\><C-N>")
nmap("<C-x>", "<cmd>!chmod +x %")

vim.api.nvim_create_user_command('BlameOn', 'GitBlameEnable', {})
vim.api.nvim_create_user_command('BlameOff', 'GitBlameDisable', {})
vim.api.nvim_create_user_command('Blame', 'GitBlameToggle', {})


NEOVIM_VENV = os.getenv("NEOVIM_VENV")


vim.g.python_indent = {}
vim.g.python_indent.closed_paren_align_last_line = false
vim.g.python_indent.open_paren = "shiftwidth()"
vim.g.python_indent.continue = "shiftwidth()"
vim.g.python3_host_prog = NEOVIM_VENV .. "/bin/python3"
vim.g.context_enabled = 1
vim.g.context_add_mappings = 1
vim.g.context_add_autocmds = 1
vim.g.context_max_height = 21
vim.g.context_max_per_indent = 11
vim.g.context_skip_regex = "^\\s*($|#|//|/\\*)"
require('gitblame').setup({
    enabled = false,
})
vim.g.gitblame_display_virtual_text = 1
vim.g.gitblame_date_format = "%r"
vim.g.gitblame_message_template = "    <author>, <date> • [<sha>] <summary>"


-- require("rose-pine").setup({
-- 	variant = "auto",
-- 	dark_variant = "main",
-- 	enable = {
-- 		terminal = true,
-- 	},
-- 	styles = {
-- 		bold = false,
-- 		italic = false,
-- 		transparency = true,
-- 	},
--     groups = {
--         border = "muted",
--         link = "iris",
--         panel = "surface",
-- 
--         error = "love",
--         hint = "iris",
--         info = "foam",
--         note = "pine",
--         todo = "rose",
--         warn = "gold",
-- 
--         git_add = "foam",
--         git_change = "rose",
--         git_delete = "love",
--         git_dirty = "rose",
--         git_ignore = "muted",
--         git_merge = "iris",
--         git_rename = "pine",
--         git_stage = "iris",
--         git_text = "rose",
--         git_untracked = "subtle",
-- 
--         h1 = "iris",
--         h2 = "foam",
--         h3 = "rose",
--         h4 = "gold",
--         h5 = "pine",
--         h6 = "foam",
--     },
-- })


local harpoon = require("harpoon")
harpoon:setup()
vim.keymap.set("n", "<space>a", function() harpoon:list():append() end)
vim.keymap.set("n", "<space>d", function() harpoon:list():remove() end)
vim.keymap.set("n", "<space>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)


local neovim_venv = os.getenv("NEOVIM_VENV") or os.getenv("HOME") .."/venvs/neovim_venv"

-- Linter config
require('lspconfig').pylsp.setup({
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
})

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

--Below was causing problems with standalone Python files.
-- local configs = require('lspconfig.configs')
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

require('lspconfig').ruff_lsp.setup({
    cmd = { neovim_venv .. "/bin/ruff-lsp" },
    on_attach = on_attach,
    init_options = {
        settings = {
            -- Any extra CLI arguments for `ruff` go here.
            args = {},
        }
    }
})


require('nvim-treesitter.configs').setup({
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },
    indent = {
        enable = true
    }
})


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

-- nvim-tree: Disable netrw, show icons, sync tab presence
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
require('telescope').setup({
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
local cmp = require('cmp')
cmp.setup({
  --snippet = {
  --  expand = function(args)
  --    vim.fn["vsnip#anonymous"](args.body)
  --  end,
  --},
  mapping = cmp.mapping.preset.insert({
    ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.select_next_item()
        else
            fallback()
        end
    end, { 'i', 's' }),

    ['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.select_prev_item()
        else
            fallback()
        end
    end, { 'i', 's' }),

--    ['<CR>'] = cmp.mapping(function(fallback)
--        if cmp.visible() then
--            cmp.abort()
--        end
--        fallback()
--    end, { 'i', 's' }),

    ['<C-y>'] = cmp.mapping.confirm({ select = true }),

    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    --['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'nvim_lsp_signature_help' },
    --{ name = 'vsnip' },
  }, {
    { name = 'buffer' },
  })
})
