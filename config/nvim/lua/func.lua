-- Print absolute path to current file
vim.api.nvim_create_user_command('Where', function()
    local filePath = vim.api.nvim_buf_get_name(0)
    local result = vim.fn.resolve(vim.fs.normalize(filePath))
    print(result)
end, {})

-- Print absolute path to current file and copy to system clipboard
vim.api.nvim_create_user_command('WhereCopy', function()
    local filePath = vim.api.nvim_buf_get_name(0)
    local result = vim.fn.resolve(vim.fs.normalize(filePath))
    print(result)

    result = result:gsub("\n", "")
    vim.fn.setreg("+", result)
end, {})
