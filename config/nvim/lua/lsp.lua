local neovim_venv = os.getenv("NEOVIM_VENV") or os.getenv("HOME") .. "/venvs/neovim_venv"

-- Keybinds for lsp diagnostics
local opts = { noremap=true, silent=true }
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)

-- LSP-specific behavior per buffer
local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap=true, silent=true, buffer=bufnr }
    --vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
    --vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
    vim.keymap.set(
        "n",
        "<leader>f",
        function() vim.lsp.buf.format { async = true } end,
        bufopts
    )
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
vim.o.updatetime = 500

-- Linter: Configure display of linting messages in-line
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded" }
})


-- Secondary language server for Python, only used here for code formatting
vim.lsp.config['ruff'] = {
    filetypes = { 'python' },
    on_attach = on_attach,
    cmd = { neovim_venv .. "/bin/ruff", "server" },
    init_options = {
        settings = {
            args = {"--isolated"},
            organizeImports = false,
            lint = {
                enable = false
            }
        }
    }
}

-- C/C++ language server
vim.lsp.config['clangd'] = {
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "compile_flags.txt", "configure.ac", ".git" },
    on_attach = on_attach,
    cmd = {
        "clangd",
        "--background-index",
        "--completion-style=detailed",

        -- "--suggest-missing-includes",
        -- "--clang-tidy",
        "--fallback-style=WebKit"
    },
    capabilities = {
        textDocument = {
            formatting = {
                formatProvider = "clang-format"
            }
        }
    }
}

-- Rust language server
vim.lsp.config['rust_analyzer'] = {
    filetypes = { "rust" },
    on_attach = on_attach,
    cmd = { "rust-analyzer" }
}


vim.lsp.enable({'ruff', 'clangd', 'rust_analyzer'})

--require("custom.basedpyright").setup_basedpyright(neovim_venv, on_attach)
require("custom.ty").setup_ty(neovim_venv, on_attach)
