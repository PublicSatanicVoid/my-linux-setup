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

vim.cmd [[
augroup qs_colors
    autocmd!
    autocmd ColorScheme * highlight QuickScopePrimary guifg='#afff5f' gui=underline ctermfg=155 cterm=underline
    autocmd ColorScheme * highlight QuickScopeSecondary guifg='#5fffff' gui=underline ctermfg=81 cterm=underline
augroup END
]]

require("lazy").setup({
    {"nvim-lualine/lualine.nvim", event = "VeryLazy",
        config = function()
            require("lualine").setup({
                options = {
                    icons_enabled = false,
                    theme = "auto",
                    refresh = {
                        statusline = 5000,
                    }
                },
                sections = {
                    lualine_a = {"mode"},
                    lualine_b = {"branch", "diagnostics"},
                    lualine_c = {"filename"},
                    lualine_y = {"progress"},
                    lualine_z = {"location"}
                },
            })
        end
    },

    -- "rose-pine/neovim",
    {"PublicSatanicVoid/rose-pine.nvim", 
        init = function()
            vim.cmd.colorscheme "rose-pine"
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
    
    {"nvim-telescope/telescope.nvim", event = "VeryLazy"},
    
    {"mihaifm/bufstop", event = "VeryLazy"},
    
    {"nvim-tree/nvim-tree.lua", event = "VeryLazy",
        config = function()
            -- nvim-tree: Disable netrw, show icons, sync tab presence
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1
            require("nvim-tree").setup()
        end
    },

    -- Load immediately or else LSP breaks
    {"neovim/nvim-lspconfig",
        config = function()
            local opts = { noremap=true, silent=true }
            vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
            vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
            vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
            vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)

            local on_attach = function(client, bufnr)
                -- Enable completion triggered by <c-x><c-o>
                vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

                -- Mappings.
                -- See `:help vim.lsp.*` for documentation on any of the below functions
                local bufopts = { noremap=true, silent=true, buffer=bufnr }
                --vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
                vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
                vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
                vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
                --vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
                vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
                vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, bufopts)
                vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
                vim.keymap.set("n", "<leader>wl", function()
                    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                end, bufopts)
                --vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, bufopts)
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
                vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
                vim.keymap.set("n", "<leader>f",
                    function() vim.lsp.buf.format { async = true }
                end, bufopts)
            end

            -- Linter: Show floating window with linter error on current line
            vim.api.nvim_create_autocmd({"CursorHold"}, {
                callback = function()
                    local opts = {
                        focusable = false,
                        close_events = {
                            "BufLeave", "CursorMoved", "InsertEnter", "FocusLost"
                        },
                        border = "rounded",
                        source = "always",
                        prefix = " ",
                        scope = "cursor",
                    }
                    vim.diagnostic.open_float(nil, opts)
                end
            })

            -- Show the floating window faster when trigger condition is met
            vim.o.updatetime = 1000

            -- Specify how the border looks like
            local border = "rounded"

            -- Add the border on hover and on signature help popup window
            local handlers = {
                ['textDocument/hover'] = vim.lsp.with(
                    vim.lsp.handlers.hover,
                    { border = border }
                ),
                ['textDocument/signatureHelp'] = vim.lsp.with(
                    vim.lsp.handlers.signature_help,
                    { border = border }
                ),
            }

            -- Linter: Configure display of linting messages in-line
            vim.diagnostic.config({
                virtual_text = true,
                signs = true,
                underline = true,
                update_in_insert = false,
                severity_sort = true,

                float = { border = border },
            })

            require("lspconfig").pylsp.setup({
                handlers = handlers,
                cmd = { neovim_venv .. "/bin/pylsp" },
                settings = {
                    pylsp = {
                        plugins = {
                            pylsp_mypy = { enabled = true },
                            jedi_completion = { fuzzy = true }
                        }
                    }
                },
                flags = {
                    debounce_text_changes = 200,
                },
            })

            require("lspconfig").ruff_lsp.setup({
                handlers = handlers,
                cmd = { neovim_venv .. "/bin/ruff-lsp" },
                on_attach = on_attach,
                init_options = {
                    settings = {
                        args = {},
                    }
                }
            })

            --require("lspconfig").bashls.setup({})

            require("lspconfig").clangd.setup({
                handlers = handlers
            })

            require("lspconfig").rust_analyzer.setup({
                handlers = handlers
            })

        end
    },

    {"williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end
    },

    {"hrsh7th/nvim-cmp", event = "VeryLazy",
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                completion = cmp.config.window.bordered(),

                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },

                mapping = cmp.mapping.preset.insert({
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),

                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),

                    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-Space>"] = cmp.mapping.confirm({ select = true }),

                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-e>"] = cmp.mapping.abort(),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "nvim_lsp_signature_help" },
                }, {
                    { name = "buffer" },
                })
            })
        end
    },

    {"hrsh7th/cmp-nvim-lsp", event = "VeryLazy"},
    
    {"hrsh7th/cmp-buffer", event = "VeryLazy"},
    -- "hrsh7th/cmp-path",
    -- "hrsh7th/cmp-cmdline",
    -- "hrsh7th/vim-vsnip",
    -- "hrsh7th/cmp-vsnip",
    -- "hrsh7th/vim-vsnip-integ",
    {"hrsh7th/cmp-nvim-lsp-signature-help", event = "VeryLazy"},

    -- Load immediately so the colors don't flash
    {"nvim-treesitter/nvim-treesitter", event = "VimEnter",
        config = function()
            require('nvim-treesitter.configs').setup({
                ensure_installed = { "c", "lua", "vim", "bash", "python", "rust" },
                auto_install = true,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = {
                    enable = true,

                    -- Treesitter indents 2x shiftwidth in certain situations; not
                    -- configurable, so drop treesitter's python indentation entirely
                    -- and fall back to defaults (which are exactly what I want)
                    disable = { "python" },
                }
            })
        end
    },

    -- Load immediately or else it breaks
    -- "wellle/context.vim",
    {"Hippo0o/context.vim"},  -- fork that fixes issues with the original

    {"ojroques/vim-oscyank", event = "VeryLazy"},
    
    {"f-person/git-blame.nvim", event = "VeryLazy",
        config = function()
            vim.api.nvim_create_user_command("BlameOn", "GitBlameEnable", {})
            vim.api.nvim_create_user_command("BlameOff", "GitBlameDisable", {})
            vim.api.nvim_create_user_command("Blame", "GitBlameToggle", {})
            require("gitblame").setup({
                enabled = false,
            })
            vim.g.gitblame_display_virtual_text = 1
            vim.g.gitblame_date_format = "%r"
            vim.g.gitblame_message_template = "    <author>, <date> • [<sha>] <summary>"
        end
    },
    
    {"ThePrimeagen/harpoon", branch = "harpoon2", event = "VeryLazy",
        config = function()
            local harpoon = require("harpoon")
            harpoon:setup()
            vim.keymap.set("n", "<leader>a", function() harpoon:list():append() end)
            vim.keymap.set("n", "<leader>d", function() harpoon:list():remove() end)
            vim.keymap.set("n", "<leader>h", function()
                harpoon.ui:toggle_quick_menu(harpoon:list())
            end)
        end
    },

    {"mbbill/undotree", event = "VeryLazy"},

    {"folke/zen-mode.nvim", event = "VeryLazy",
        --config = function()
        --    require("zen-mode").setup({
        --        window = {
        --            width = 120
        --        }
        --    })
        --end
    },

    {"nvim-pack/nvim-spectre", event = "VeryLazy"},

    -- :Subvert/search/replace/g  to replace search, Search, SEARCH with case-matched
    -- replace
    -- And also supports variants, like :Subvert/ba{r,z}/car{,s}/g
    {"tpope/vim-abolish", event = "VeryLazy"},

    {"unblevable/quick-scope", event = "VeryLazy"},

    {"ThePrimeagen/vim-be-good", event = "VeryLazy"}
})
