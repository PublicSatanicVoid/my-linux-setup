local neovim_venv = os.getenv("NEOVIM_VENV") or os.getenv("HOME") .. "/venvs/neovim_venv"
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

vim.lsp.config['pylsp'] = {
    filetypes = { 'python' },
    handlers = handlers,
    cmd = { neovim_venv .. "/bin/pylsp", "-vvv" },
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
}
vim.lsp.enable('pylsp')

vim.lsp.config['ruff'] = {
    filetypes = { 'python' },
    handlers = handlers,
    cmd = { neovim_venv .. "/bin/ruff", "server" },
    on_attach = on_attach,
    init_options = {
        settings = {
            args = {"--isolated"},
            organizeImports = false,
        }
    }
}
vim.lsp.enable('ruff')

--L.bashls.setup({})

vim.lsp.config['clangd'] = {
    filetypes = { 'c', 'c++' },
    handlers = handlers,
    cmd = {
        "clangd",
        "--background-index",
        -- "--suggest-missing-includes",
        -- "--clang-tidy",
        "--completion-style=detailed",

        -- '--fallback-style="{BasedOnStyle: llvm, IndentWidth: 4}"',
    },
    capabilities = {
        textDocument = {
            formatting = {
                formatProvider = "clang-format"
            }
        }
    }
}
vim.lsp.enable('clangd')


vim.lsp.config['rust_analyzer'] = {
    filetypes = { 'rust' },
    handlers = handlers
}
vim.lsp.enable('rust_analyzer')
