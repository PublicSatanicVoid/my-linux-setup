local neovim_venv = os.getenv("NEOVIM_VENV") or os.getenv("HOME") .. "/venvs/neovim_venv"
local T = {
--Lualine causes the cursor to disappear occasionally.
--[===[
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
--]===]
    {"pixelastic/vim-undodir-tree"},

    {"nvim-tree/nvim-web-devicons",
        config = function()
            require("nvim-web-devicons").setup()
        end
    },

    -- -- disabled 20240926 due to slow autofs
    -- {"lewis6991/gitsigns.nvim",
    --     config = function()
    --         require("gitsigns").setup({
    --             signcolumn = false
    --         })
    --     end
    -- },

    -- Okay, this also causes the cursor to disappear occasionally, but a lot less often.
    -- "famiu/feline.nvim",
    {"PublicSatanicVoid/feline.nvim",
        config = function()
            local feline = require("feline")
            feline.setup()

            ---[===[
            local palette = require("rose-pine.palette")
            
            theme = {
                red = palette.rose,
                --red = palette.love,
                oceanblue = palette.overlay,
                --bg = palette.base,
                bg = "NONE",
                fg = palette.text,
                skyblue = palette.foam,
                green = palette.iris,
            }

            feline.use_theme(theme)
            ---]===]

        end
    },

--[===[
    {"rebelot/kanagawa.nvim",
        init = function()
            vim.cmd.colorscheme "kanagawa"
        end,
        config = function()
            require("kanagawa").setup({
                compile = true,  -- remember to rerun :KanagawaCompile to reconfig
                undercurl = false,
                commentStyle = { italic = false },
                keywordStyle = { italic = false },
                statementStyle = { bold = false },
                transparent = true,
                theme = "wave",
                colors = {
                    theme = {
                        all = {
                            ui = {
                                bg_gutter = "none",
                                --bg = "none"
                            }
                        }
                    }
                }
            })
        end,
    },
--]===]
    
--[===[
    {"AlexvZyl/nordic.nvim",
        -- lazy = false,
        -- priority = 1000,
        init = function()
            vim.cmd.colorscheme "nordic"
        end,
        config = function()
            require("nordic").setup({
                italic_comments = false,
                transparent = {
                    bg = true,
                    float = true,
                },
                bright_border = true,
                reduced_blue = true,
                cursorline = {
                    bold = false,
                    bold_number = true,
                    theme = 'dark',
                    blend = 0.95,
                },
                ts_context = {
                    dark_background = false,
                },
            })
        end
    },
--]===]

--[===[
    {"projekt0n/github-nvim-theme",
        name = "github-theme",
        lazy = false,
        priority = 1000,
        init = function()
            vim.cmd.colorscheme "github_dark"
        end,
        config = function()
            require("github-theme").setup({
                options = {
                    transparent = true,
                    darken = {
                        floats = false,
                    },
                }
            })
        end
    },
--]===]
        

---[===[
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
---]===]

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
                vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
                vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
                vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
                vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
                vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
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

	    local L = require("lspconfig")

            L.pylsp.setup({
                handlers = handlers,
                cmd = { neovim_venv .. "/bin/pylsp" },
                settings = {
                    pylsp = {
                        plugins = {
                            -- sorts imports on format, boo hiss
                            autopep8 = { enabled = false },

                            -- redundant with ruff
                            pycodestyle = { enabled = false },
                            pyflakes = { enabled = false },
                            yapf = { enabled = false },
                            black = { enabled = false },

                            pylsp_mypy = { enabled = true },
                            --pycodestyle = {
                            --    maxLineLength = 88,
                            --    ignore = {'E701', 'W503'},
                            --},
                            jedi_completion = { fuzzy = true },
                            jedi_symbols = {
                                include_import_symbols = false
                            },
                            mccabe = { threshold = 100 },
                        }
                    }
                },
                flags = {
                    debounce_text_changes = 200,
                },
            })

            L.ruff_lsp.setup({
                handlers = handlers,
                cmd = { neovim_venv .. "/bin/ruff-lsp" },
                on_attach = on_attach,
                init_options = {
                    settings = {
		    	args = {"--isolated"},
                        organizeImports = false,
                    }
                }
            })

            --L.bashls.setup({})

            L.clangd.setup({
                handlers = handlers,
                cmd = {
                    "clangd",
                    "--background-index",
                    "--suggest-missing-includes",
                --    "--clang-tidy",
                    "--completion-style=detailed"
                }
            })

            L.rust_analyzer.setup({
                handlers = handlers
            })

            L.arduino_language_server.setup({
                handlers = handlers
            })

        end
    },

    --{"williamboman/mason.nvim",
    --    config = function()
    --        require("mason").setup()
    --    end
    --},

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
    -- NOTE: Both of these were causing terrible slowness when scrolling,
    -- 	so I replaced them with nvim-treesitter-context
    -- "wellle/context.vim",
    --{"Hippo0o/context.vim"},  -- fork that fixes issues with the original
    
    {"nvim-treesitter/nvim-treesitter-context",
        config = function()
            require("treesitter-context").setup({
                enable = true,
                max_lines = 0,
                min_window_height = 0,
                line_numbers = true,
                multiline_threshold = 2,
                trim_scope = 'outer',
                mode = 'cursor',
                separator = '—',
                zindex = 20,
                on_attach = nil,
            })

            vim.cmd "hi TreesitterContext guibg=none"
        end
    },

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
            vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
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
}
return T
