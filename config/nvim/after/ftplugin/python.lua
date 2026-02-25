-- Don't auto-wrap text or comments when they exceed textwidth.
-- Keeps textwidth in effect for colorcolumn and manual gq formatting.
vim.opt_local.formatoptions:remove("t")
vim.opt_local.formatoptions:remove("c")
