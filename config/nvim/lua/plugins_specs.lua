local neovim_venv = os.getenv("NEOVIM_VENV") or os.getenv("HOME") .. "/venvs/neovim_venv"
local T = {
    {"nvim-lualine/lualine.nvim", event = "VeryLazy",
        config = function()
            require("lualine").setup({
                options = {
                    icons_enabled = false,
                    theme = "auto",
                    --refresh = {
                    --    statusline = 5000,
                    --}
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
                statementStyle = { italic = false, bold = false },
                typeStyle = { italic = false },
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
    {"catppuccin/nvim", name="catppuccin", priority=1000,
        init = function()
            vim.cmd.colorscheme "catppuccin-mocha"
        end,
	config = function()
	    require("catppuccin").setup({
                no_italic = true,
			transparent_background = true,
			styles = {
				comments = {},
				conditionals = {},
				loops = {},
				functions = {},
				keywords = {},
				strings = {},
				variables = {},
				numbers = {},
				booleans = {},
				properties = {},
				types = {},
			},
		color_overrides = {
		    mocha = {
		        base = "#000000",
			mantle = "#000000",
			crust = "#000000",
		    }
		},
	    })
	end,
		
    },
--]===]


---[===[
    { 
        "PublicSatanicVoid/nightfox.nvim",
        -- "EdenEast/nightfox.nvim",
        init = function()
            vim.cmd.colorscheme "terafox"
        end,
        config = function()
            require("nightfox").setup({
                options = {
                    transparent = true,
                }
            })
        end,
    },
---]===]


--[===[
    -- "rose-pine/neovim",
    {"PublicSatanicVoid/rose-pine.nvim", 
        init = function()
            --vim.cmd.colorscheme "rose-pine"
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
--]===]

--[===[
    {"neanias/everforest-nvim",
        init = function()
            vim.cmd.colorscheme "everforest"
        end
    },
--]===]

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

                    -- Required to get indentation working correctly for Python
                    additional_vim_regex_highlighting = true,
                },
                indent = {
                    enable = true,  -- Experimental and totally sucks for Python

                    -- Treesitter indents 2x shiftwidth in certain situations; not
                    -- configurable, so drop treesitter's python indentation entirely
                    -- and fall back to defaults (which are exactly what I want)
                    disable = { "python", "yaml" },
                }
            })

            -- Somehow these get overridden
            opt = vim.opt
            opt.tabstop = 4
            opt.softtabstop = 4
            opt.shiftwidth = 4
            --opt.expandtab = true
            opt.autoindent = true
            opt.smartindent = true
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
