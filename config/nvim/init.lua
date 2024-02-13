local neovim_venv = os.getenv("NEOVIM_VENV") or os.getenv("HOME") .. "/venvs/neovim_venv"

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
    {"nvim-lualine/lualine.nvim", event = 'VeryLazy',
        config = function()
            require('lualine').setup({
                options = {
                    icons_enabled = false,
                    theme = 'auto',
                    refresh = {
                        statusline = 5000,
                    }
                },
                sections = {
                    lualine_a = {'mode'},
                    lualine_b = {'branch', 'diagnostics'},
                    lualine_c = {'filename'},
                    lualine_y = {'progress'},
                    lualine_z = {'location'}
                },
            })
	    end
    },

    -- "rose-pine/neovim",
    {"PublicSatanicVoid/rose-pine.nvim", 
        init = function()
            vim.cmd.colorscheme 'rose-pine'
        end,
        config = function()
            require("rose-pine").setup({
                variant = "auto",
                dark_variant = "main",
                enable = {
                    terminal = true,
                },
                styles = {
                    bold = false,
                    italic = false,
                    transparency = true,
                },
            })
        end
    },  -- fork with softer whites
    
    {"nvim-lua/plenary.nvim"},
    
    {"nvim-telescope/telescope.nvim", event = 'VeryLazy',
        config = function()
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
        end
    },
    
    {"mihaifm/bufstop", event = 'VeryLazy'},
    
    {"nvim-tree/nvim-tree.lua", event = 'VeryLazy',
        config = function()
            -- nvim-tree: Disable netrw, show icons, sync tab presence
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1

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
        end
    },

    -- Load immediately or else LSP breaks
    {"neovim/nvim-lspconfig", --event = 'VimEnter', --event = 'BufRead *',
        config = function()
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
                --capabilities = capabilities,
            })

            require('lspconfig').ruff_lsp.setup({
                cmd = { neovim_venv .. "/bin/ruff-lsp" },
                on_attach = on_attach,
                init_options = {
                    settings = {
                        args = {},
                    }
                }
            })
        end
    },

    {"hrsh7th/nvim-cmp", event = 'VeryLazy',
        config = function()
            local cmp = require('cmp')
            cmp.setup({
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

                    ['<C-y>'] = cmp.mapping.confirm({ select = true }),

                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-e>'] = cmp.mapping.abort(),
                }),
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'nvim_lsp_signature_help' },
                }, {
                    { name = 'buffer' },
                })
            })
        end
    },

    {"hrsh7th/cmp-nvim-lsp", event = 'VeryLazy'},
    
    {"hrsh7th/cmp-buffer", event = 'VeryLazy'},
    -- "hrsh7th/cmp-path",
    -- "hrsh7th/cmp-cmdline",
    -- "hrsh7th/vim-vsnip",
    -- "hrsh7th/cmp-vsnip",
    -- "hrsh7th/vim-vsnip-integ",
    {"hrsh7th/cmp-nvim-lsp-signature-help", event = 'VeryLazy'},

    -- Load immediately so the colors don't flash
    {"nvim-treesitter/nvim-treesitter", event = 'VimEnter',
        config = function()
            require('nvim-treesitter.configs').setup({
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = {
                    enable = true
                }
            })
        end
    },

    -- Load immediately or else it breaks
    -- "wellle/context.vim",
    {"Hippo0o/context.vim"},  -- fork that fixes issues with the original

    -- Nice to have sometimes but too annoying when it's not
    -- {"jiangmiao/auto-pairs"},
    
    {"ojroques/vim-oscyank", event = 'VeryLazy'},
    
    {"f-person/git-blame.nvim", event = 'VeryLazy',
        config = function()
            vim.api.nvim_create_user_command('BlameOn', 'GitBlameEnable', {})
            vim.api.nvim_create_user_command('BlameOff', 'GitBlameDisable', {})
            vim.api.nvim_create_user_command('Blame', 'GitBlameToggle', {})
            require('gitblame').setup({
                enabled = false,
            })
            vim.g.gitblame_display_virtual_text = 1
            vim.g.gitblame_date_format = "%r"
            vim.g.gitblame_message_template = "    <author>, <date> • [<sha>] <summary>"
        end
    },
    
    {"ThePrimeagen/harpoon", branch = "harpoon2", event = 'VeryLazy',
        config = function()
            local harpoon = require("harpoon")
            harpoon:setup()
            vim.keymap.set("n", "<space>a", function() harpoon:list():append() end)
            vim.keymap.set("n", "<space>d", function() harpoon:list():remove() end)
            vim.keymap.set("n", "<space>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
        end
    },

    {"mbbill/undotree", event = 'VeryLazy'}
})

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
--vim.cmd [[
--    filetype plugin on
--    filetype plugin indent on
--]]
--vim.opt.autoindent = true --Not sure about this one, TODO
vim.opt.smartindent = true
vim.opt.number = true
vim.opt.relativenumber = true
--vim.opt.wildmode = {"longest", "list"}  --is that how you do this?
vim.opt.colorcolumn = "89"
vim.opt.textwidth = 89
vim.opt.ttyfast = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
vim.opt.scrolloff = 10
vim.opt.showmode = false  -- lualine does this now
--set vb t_vb=  --how to do this in lua?

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
nmap("<C-f>", "<cmd>Telescope find_files<CR>")
nmap("<S-f>", "<cmd>Telescope live_grep<CR>")
nmap("<C-l>", "<cmd>NvimTreeToggle<CR>")
nmap("/", ":%s###gn<Left><Left><Left><Left>")
vmap("<space>y", "<Plug>OSCYankVisual")
nmap("<space>y", "<Plug>OSCYankVisual")
nmap("<space>b", "<cmd>BufstopFast<CR>")
nmap("<space>n", "<cmd>bprev<CR>")
nmap("<space>p", "<cmd>bnext<CR>")
nmap("<space>u", "<cmd>UndotreeToggle<CR>")
tmap("<esc>", "<C-\\><C-N>")
nmap("<C-x>", "<cmd>!chmod +x %<CR>")
nmap("<C-b>", "<C-v>")

vim.g.context_enabled = 1
vim.g.context_add_mappings = 1
vim.g.context_add_autocmds = 1
vim.g.context_max_height = 21
vim.g.context_max_per_indent = 11
vim.g.context_skip_regex = "^\\s*($|#|//|/\\*)"

vim.g.python_indent = {}
vim.g.python_indent.closed_paren_align_last_line = false
vim.g.python_indent.open_paren = "shiftwidth()"
vim.g.python_indent.continue = "shiftwidth()"
vim.g.python3_host_prog = neovim_venv .. "/bin/python3"

vim.cmd [[
function! CenterContent()
    let l:textwidth = 120

    let l:width = winwidth(0)
    let l:margin = (l:width - l:textwidth) / 2

    setlocal nosplitright
    vsplit
    enew
    setlocal nomodifiable
    setlocal nonumber
    setlocal norelativenumber
    setlocal fillchars=eob:\ "
    execute 'vertical resize ' . l:margin
    wincmd l
    setlocal splitright
    vsplit
    enew
    setlocal nomodifiable
    setlocal nonumber
    setlocal norelativenumber
    setlocal fillchars=eob:\ "
    execute 'vertical resize ' . l:margin
    wincmd h
endfunction
command! Focus call CenterContent()

function! UnCenterContent()
    wincmd h
    q
    wincmd l
    q
endfunction
command! UnFocus call UnCenterContent()
]]


