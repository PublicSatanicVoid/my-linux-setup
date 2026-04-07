if vim.loader then
    vim.loader.enable()
end
require("set")
require("plugins")
require("remap")
require("func")
require("lsp")
