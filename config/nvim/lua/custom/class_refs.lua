local M = {}

local api = vim.api
local lsp_util = require("vim.lsp.util")

local function get_module_path(filepath)
    local fn = vim.fn
    local dir = fn.fnamemodify(filepath, ":h")
    local name = fn.fnamemodify(filepath, ":t:r")
    if name == "__init__" then
        name = fn.fnamemodify(dir, ":t")
        dir = fn.fnamemodify(dir, ":h")
    end
    
    local parts = { name }
    while fn.filereadable(dir .. "/__init__.py") == 1 do
        table.insert(parts, 1, fn.fnamemodify(dir, ":t"))
        dir = fn.fnamemodify(dir, ":h")
    end
    return table.concat(parts, ".")
end

local function parse_file(filepath)
    local lines = vim.fn.readfile(filepath)
    local content_str = table.concat(lines, "\n")
    local parser = vim.treesitter.get_string_parser(content_str, "python")
    local tree = parser:parse()[1]
    return tree, content_str, lines
end

local function get_node_at_range(root, range)
    local s_line = range.start.line
    local s_col = range.start.character
    local e_line = range["end"].line
    local e_col = range["end"].character
    -- treesitter ranges are 0-indexed, and end column is exclusive
    return root:named_descendant_for_range(s_line, s_col, e_line, e_col)
end

local function find_enclosing(node, content_str)
    local class_name, class_range
    local func_name, func_range
    local curr = node
    while curr do
        if curr:type() == "class_definition" and not class_name then
            local name_node = curr:field("name")[1]
            if name_node then
                class_name = vim.treesitter.get_node_text(name_node, content_str)
                local s_r, s_c, e_r, e_c = curr:range()
                class_range = {
                    start = { line = s_r, character = s_c },
                    ["end"] = { line = e_r, character = e_c }
                }
            end
        elseif curr:type() == "function_definition" and not func_name then
            local name_node = curr:field("name")[1]
            if name_node then
                func_name = vim.treesitter.get_node_text(name_node, content_str)
                local s_r, s_c, e_r, e_c = curr:range()
                func_range = {
                    start = { line = s_r, character = s_c },
                    ["end"] = { line = e_r, character = e_c }
                }
            end
        end
        curr = curr:parent()
    end
    return class_name, class_range, func_name, func_range
end

local function jump_to_location(uri, range)
    if not uri or not range then return end
    local bufnr = vim.uri_to_bufnr(uri)
    vim.fn.bufload(bufnr)
    vim.api.nvim_set_current_buf(bufnr)
    -- lsp ranges are 0-indexed for line
    vim.api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
    vim.cmd("normal! zz")
end

local function open_tree_window(lines, targets)
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    api.nvim_buf_set_option(buf, "modifiable", false)
    api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    api.nvim_buf_set_option(buf, "filetype", "python_class_refs")

    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    
    local win = api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " Class References ",
        title_pos = "center",
    })

    -- Add highlighting
    api.nvim_buf_add_highlight(buf, -1, "Directory", 0, 0, -1) -- we'll do real highlighting below

    for i, line in ipairs(lines) do
        local is_leaf = string.match(line, "^      ")
        local is_func = string.match(line, "^    [^ ]")
        local is_class = string.match(line, "^  [^ ]")
        local is_mod = not (is_leaf or is_func or is_class)
        
        local lnum = i - 1
        if is_mod then
            api.nvim_buf_add_highlight(buf, -1, "Directory", lnum, 0, -1)
        elseif is_class then
            api.nvim_buf_add_highlight(buf, -1, "Type", lnum, 0, -1)
        elseif is_func then
            api.nvim_buf_add_highlight(buf, -1, "Function", lnum, 0, -1)
        else
            api.nvim_buf_add_highlight(buf, -1, "Comment", lnum, 0, -1)
        end
    end

    -- Keybinds
    local opts = { noremap = true, silent = true, buffer = buf }
    vim.keymap.set("n", "<CR>", function()
        local cursor = api.nvim_win_get_cursor(win)
        local lnum = cursor[1]
        local target = targets[lnum]
        if target then
            api.nvim_win_close(win, true)
            jump_to_location(target.uri, target.range)
        end
    end, opts)

    vim.keymap.set("n", "q", function()
        api.nvim_win_close(win, true)
    end, opts)
    vim.keymap.set("n", "<Esc>", function()
        api.nvim_win_close(win, true)
    end, opts)
end

function M.find_class_references()
    local bufnr = api.nvim_get_current_buf()
    local win = api.nvim_get_current_win()
    local pos = api.nvim_win_get_cursor(win)
    local params = vim.lsp.util.make_position_params(win, "utf-8")
    
    -- Step 1: Definition to check if it's a class
    vim.lsp.buf_request(bufnr, "textDocument/definition", params, function(err, result, ctx)
        if err or not result or vim.tbl_isempty(result) then
            vim.notify("Could not find definition of symbol under cursor.", vim.log.levels.WARN)
            return
        end

        local def = result[1] or result
        local def_uri = def.uri or def.targetUri
        local def_range = def.range or def.targetSelectionRange
        local def_filepath = vim.uri_to_fname(def_uri)

        local ok, tree, content_str = pcall(parse_file, def_filepath)
        if not ok then
            vim.notify("Failed to parse definition file.", vim.log.levels.ERROR)
            return
        end

        local root = tree:root()
        local node = get_node_at_range(root, def_range)
        
        local class_name, _
        local curr = node
        while curr do
            if curr:type() == "class_definition" then
                local name_node = curr:field("name")[1]
                if name_node then
                    class_name = vim.treesitter.get_node_text(name_node, content_str)
                end
                break
            end
            curr = curr:parent()
        end

        if not class_name then
            vim.notify("Error: Symbol is not a class.", vim.log.levels.ERROR)
            return
        end

        local mod_path = get_module_path(def_filepath)
        vim.notify("Class: " .. mod_path .. "." .. class_name, vim.log.levels.INFO)

        -- Step 2: References
        local ref_params = vim.lsp.util.make_position_params(win, "utf-8")
        ref_params.context = { includeDeclaration = false }
        
        vim.lsp.buf_request(bufnr, "textDocument/references", ref_params, function(r_err, r_result, r_ctx)
            if r_err or not r_result or vim.tbl_isempty(r_result) then
                vim.notify("No references found.", vim.log.levels.INFO)
                return
            end

            -- Build tree
            local t = {}
            for _, ref in ipairs(r_result) do
                local filepath = vim.uri_to_fname(ref.uri)
                local m_path = get_module_path(filepath)
                local m_ok, r_tree, r_content_str, r_lines = pcall(parse_file, filepath)
                if m_ok then
                    local r_root = r_tree:root()
                    local r_node = get_node_at_range(r_root, ref.range)
                    local c_name, c_range, f_name, f_range = find_enclosing(r_node, r_content_str)
                    
                    c_name = c_name or "(module level)"
                    f_name = f_name or "(class/module level)"
                    
                    if not t[m_path] then t[m_path] = { uri = ref.uri, range = {start={line=0,character=0}}, classes = {} } end
                    if not t[m_path].classes[c_name] then t[m_path].classes[c_name] = { uri = ref.uri, range = c_range, funcs = {} } end
                    if not t[m_path].classes[c_name].funcs[f_name] then t[m_path].classes[c_name].funcs[f_name] = { uri = ref.uri, range = f_range, refs = {} } end
                    
                    local line_text = r_lines[ref.range.start.line + 1] or ""
                    line_text = vim.trim(line_text)
                    table.insert(t[m_path].classes[c_name].funcs[f_name].refs, {
                        uri = ref.uri,
                        range = ref.range,
                        text = line_text
                    })
                end
            end

            -- Flatten tree
            local lines = {}
            local targets = {}
            
            -- Sort modules
            local m_names = vim.tbl_keys(t)
            table.sort(m_names)
            for _, m_name in ipairs(m_names) do
                table.insert(lines, m_name)
                table.insert(targets, { uri = t[m_name].uri, range = t[m_name].range })
                
                local c_names = vim.tbl_keys(t[m_name].classes)
                table.sort(c_names)
                for _, c_name in ipairs(c_names) do
                    table.insert(lines, "  " .. c_name)
                    table.insert(targets, { uri = t[m_name].classes[c_name].uri, range = t[m_name].classes[c_name].range })
                    
                    local f_names = vim.tbl_keys(t[m_name].classes[c_name].funcs)
                    table.sort(f_names)
                    for _, f_name in ipairs(f_names) do
                        table.insert(lines, "    " .. f_name)
                        table.insert(targets, { uri = t[m_name].classes[c_name].funcs[f_name].uri, range = t[m_name].classes[c_name].funcs[f_name].range })
                        
                        for _, ref in ipairs(t[m_name].classes[c_name].funcs[f_name].refs) do
                            local filename = vim.fn.fnamemodify(vim.uri_to_fname(ref.uri), ":t")
                            local display_text = string.format("      %s:%d:%d - %s", filename, ref.range.start.line + 1, ref.range.start.character, ref.text)
                            table.insert(lines, display_text)
                            table.insert(targets, { uri = ref.uri, range = ref.range })
                        end
                    end
                end
            end
            
            open_tree_window(lines, targets)
        end)
    end)
end

return M
