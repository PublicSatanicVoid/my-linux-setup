-- Print absolute path to current file
local function where()
    local filePath = vim.api.nvim_buf_get_name(0)
    local result = vim.fn.system("readlink -f " .. filePath)
    print(result)
end

-- Print absolute path to current file and copy to system clipboard
local function whereCopy()
    local filePath = vim.api.nvim_buf_get_name(0)
    local result = vim.fn.system("readlink -f " .. filePath)
    print(result)

    result = result:gsub("\n", "")
    vim.fn.setreg("+", result)
end

-- Quickly open NeoVim configs
local function configOpen(name)
    local basePath = vim.fn.expand("~/.config/nvim/lua/")
    local filePath = basePath .. (name and (name .. ".lua") or "init.lua")
    if name == "" then
        name = "init"
    end
    local filePath = basePath .. name .. ".lua"
    vim.cmd("edit " .. filePath)
end

-- Register the commands
vim.api.nvim_create_user_command('Where', where, {})
vim.api.nvim_create_user_command('WhereCopy', whereCopy, {})
vim.api.nvim_create_user_command(
    'Config',
    function(opts)
        configOpen(opts.args)
    end,
    { nargs = '?' }
)
