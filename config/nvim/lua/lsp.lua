local neovim_venv = os.getenv("NEOVIM_VENV") or os.getenv("HOME") .. "/venvs/neovim_venv"
local opts = { noremap=true, silent=true }
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)

local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap=true, silent=true, buffer=bufnr }
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
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
            close_events = {"BufLeave", "CursorMoved", "InsertEnter", "FocusLost"},
            border = "rounded",
            source = "always",
            prefix = " ",
            scope = "cursor"
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
    float = { border = "rounded" }
})

vim.lsp.config['pylsp'] = {
    filetypes = { 'python' },
    on_attach = on_attach,
    cmd = { neovim_venv .. "/bin/pylsp", "-vvv" },
    settings = {
        pylsp = {
            plugins = {
                -- Disable formatters that conflict with Ruff
                autopep8 = { enabled = false },
                pycodestyle = { enabled = false },
                pyflakes = { enabled = false },
                yapf = { enabled = false },
                black = { enabled = false },

                -- Enable type checking and completion
                pylsp_mypy = { enabled = true },
                jedi_completion = { fuzzy = true },
                jedi_symbols = { include_import_symbols = false },
                mccabe = { threshold = 100 }
            }
        }
    },
    flags = {
        debounce_text_changes = 200
    },
}

vim.lsp.config['ruff'] = {
    filetypes = { 'python' },
    on_attach = on_attach,
    cmd = { neovim_venv .. "/bin/ruff", "server" },
    init_options = {
        settings = {
            args = {"--isolated"},
            organizeImports = false
        }
    }
}

vim.lsp.config['clangd'] = {
    filetypes = { 'c', 'c++' },
    on_attach = on_attach,
    cmd = {
        "clangd",
        "--background-index",
        "--completion-style=detailed",

        -- "--suggest-missing-includes",
        -- "--clang-tidy",
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

vim.lsp.config['rust_analyzer'] = {
    filetypes = { 'rust' },
    on_attach = on_attach
}


vim.lsp.enable({'pylsp', 'ruff', 'clangd', 'rust_analyzer'})
