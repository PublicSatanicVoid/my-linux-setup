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

-- Register the commands
vim.api.nvim_create_user_command('Where', where, {})
vim.api.nvim_create_user_command('WhereCopy', whereCopy, {})
