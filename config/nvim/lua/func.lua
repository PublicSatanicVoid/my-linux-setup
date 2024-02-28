-- Function to execute 'readlink -f' on the current file
local function where()
  local filePath = vim.api.nvim_buf_get_name(0)
  local result = vim.fn.system("readlink -f " .. filePath)
  print(result)
end

-- Register the ':Where' command
vim.api.nvim_create_user_command('Where', where, {})
