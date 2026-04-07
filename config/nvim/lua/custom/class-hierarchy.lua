local M = {}

local api = vim.api

-- Extract Python module path from a given filepath
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

-- Jump to the target URI and specific line/col
local function jump_to_location(uri, range)
    if not uri or not range then return end
    local filepath = vim.uri_to_fname(uri)
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
    vim.api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
    vim.cmd("normal! zz")
end

-- Read and parse a python file with treesitter
local function parse_file(filepath)
    local lines = vim.fn.readfile(filepath)
    local content_str = table.concat(lines, "\n")
    local parser = vim.treesitter.get_string_parser(content_str, "python")
    return parser:parse()[1], content_str
end

-- Extract exact treesitter node for a given LSP range
local function get_node_at_range(root, range)
    return root:named_descendant_for_range(
        range.start.line, range.start.character,
        range["end"].line, range["end"].character
    )
end

-- Walk up the AST to find the closest enclosing class definition and its full name
local function find_enclosing_class(node, content_str)
    local curr = node
    local class_node = nil
    while curr do
        if curr:type() == "class_definition" then
            class_node = curr
            break
        end
        curr = curr:parent()
    end
    if not class_node then return nil, nil end

    local parts = {}
    curr = class_node
    while curr do
        if curr:type() == "class_definition" then
            local name_node = curr:field("name")[1]
            if name_node and content_str then
                table.insert(parts, 1, vim.treesitter.get_node_text(name_node, content_str))
            end
        end
        curr = curr:parent()
    end
    return table.concat(parts, "."), class_node
end

-- Create and configure the floating window for the tree
local function open_tree_window(lines, targets, target_line_idx)
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    api.nvim_buf_set_option(buf, "modifiable", false)
    api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    api.nvim_buf_set_option(buf, "filetype", "python_type_hierarchy")

    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    
    local win = api.nvim_open_win(buf, true, {
        relative = "editor", width = width, height = height,
        row = math.floor((vim.o.lines - height) / 2), col = math.floor((vim.o.columns - width) / 2),
        style = "minimal", border = "rounded",
        title = " Type Hierarchy ", title_pos = "center",
    })
    api.nvim_win_set_option(win, "cursorline", true)

    for i, line in ipairs(lines) do
        local lnum = i - 1
        if string.match(line, "^---") then
            api.nvim_buf_add_highlight(buf, -1, "Title", lnum, 0, -1)
        else
            local text_start = string.find(line, "[^%s|_\\]")
            if text_start then
                text_start = text_start - 1
                local mod_start = string.find(line, " %(", text_start + 1)
                local hl_group = (i == target_line_idx) and "String" or "Type"
                
                api.nvim_buf_add_highlight(buf, -1, hl_group, lnum, text_start, mod_start and (mod_start - 1) or -1)
                
                if mod_start then
                    api.nvim_buf_add_highlight(buf, -1, "Comment", lnum, mod_start - 1, -1)
                end
                api.nvim_buf_add_highlight(buf, -1, "Comment", lnum, 0, text_start)
            else
                api.nvim_buf_add_highlight(buf, -1, "Comment", lnum, 0, -1)
            end
        end
    end

    if target_line_idx and target_line_idx <= #lines then
        api.nvim_win_set_cursor(win, { target_line_idx, 0 })
    end

    local opts = { noremap = true, silent = true, buffer = buf }
    
    -- Jump to class definition
    vim.keymap.set("n", "<CR>", function()
        local lnum = api.nvim_win_get_cursor(win)[1]
        if targets[lnum] then
            api.nvim_win_close(win, true)
            jump_to_location(targets[lnum].uri, targets[lnum].range)
        end
    end, opts)

    -- Add to quickfix without closing window
    vim.keymap.set("n", "<Tab>", function()
        local lnum = api.nvim_win_get_cursor(win)[1]
        local target = targets[lnum]
        if target then
            local filepath = vim.uri_to_fname(target.uri)
            local clean_text = string.match(lines[lnum], "[^%s|_\\]+.*") or "Class reference"
            local qf_entry = {
                filename = filepath,
                lnum = target.range.start.line + 1,
                col = target.range.start.character + 1,
                text = clean_text
            }
            vim.fn.setqflist({qf_entry}, 'a')
            vim.notify("Added to Quickfix: " .. clean_text, vim.log.levels.INFO)
        end
    end, opts)

    -- Close window
    vim.keymap.set("n", "q", function() api.nvim_win_close(win, true) end, opts)
    vim.keymap.set("n", "<Esc>", function() api.nvim_win_close(win, true) end, opts)
end

-- Coroutine wrapper for standard LSP requests
local function async_req(buf, method, req_params)
    local co = coroutine.running()
    local status = vim.lsp.buf_request(buf, method, req_params, function(err, result, ctx)
        if type(result) == "string" and type(ctx) == "table" and not ctx.client_id then
            result = ctx
        end
        local ok, resume_err = coroutine.resume(co, err, result)
        if not ok then
            vim.notify("Async error: " .. tostring(resume_err), vim.log.levels.ERROR)
        end
    end)
    
    if not status or (type(status) == "table" and vim.tbl_isempty(status)) then
        return "LSP request failed", nil
    end
    return coroutine.yield()
end

-- Extract terminal identifiers from an import/assignment AST node
local function extract_identifiers(node, list)
    if node:type() == "aliased_import" then
        table.insert(list, node:named_child(1))
        table.insert(list, node:named_child(0))
    elseif node:type() == "dotted_name" or node:type() == "attribute" then
        table.insert(list, node:named_child(node:named_child_count() - 1))
    elseif node:type() == "identifier" then
        table.insert(list, node)
    else
        for i = 0, node:named_child_count() - 1 do
            extract_identifiers(node:named_child(i), list)
        end
    end
end

-- Main entry point
function M.show_type_hierarchy()
    local bufnr = api.nvim_get_current_buf()
    local win = api.nvim_get_current_win()
    local params = vim.lsp.util.make_position_params(win, "utf-8")
    
    coroutine.wrap(function()
        local err, result = async_req(bufnr, "textDocument/definition", params)
        if err or not result or vim.tbl_isempty(result) then
            vim.notify("Could not find definition of symbol under cursor.", vim.log.levels.WARN)
            return
        end
        
        local def = result[1] or result
        local def_uri = def.uri or def.targetUri
        local def_range = def.range or def.targetSelectionRange
        
        -- Recursively fetches ancestor hierarchy paths for a given class definition
        local function get_ancestors(uri, line, col, visited)
            local key = uri .. ":" .. line .. ":" .. col
            if visited[key] then return nil, {} end
            visited[key] = true
            
            local filepath = vim.uri_to_fname(uri)
            local ok, tree, content_str = pcall(parse_file, filepath)
            if not ok then return nil, {} end
            
            local ts_root = tree:root()
            local ts_node = get_node_at_range(ts_root, {
                start = { line = line, character = col },
                ["end"] = { line = line, character = col + 1 }
            })
            
            local name, class_node = find_enclosing_class(ts_node, content_str)
            if not class_node then
                -- Target is likely an import or assignment, follow the rabbit hole down
                local retry_nodes = {}
                local curr = ts_node
                local found_assign = false
                while curr do
                    if curr:type() == "assignment" or curr:type() == "type_alias_statement" then
                        extract_identifiers(curr:named_child(1), retry_nodes)
                        found_assign = true
                        break
                    end
                    curr = curr:parent()
                end
                
                if not found_assign then
                    extract_identifiers(ts_node, retry_nodes)
                end

                for _, r_node in ipairs(retry_nodes) do
                    if r_node then
                        local rs, rc, re, rec = r_node:range()
                        local target_bufnr = vim.uri_to_bufnr(uri)
                        vim.fn.bufload(target_bufnr)
                        local clients = (vim.lsp.get_clients and vim.lsp.get_clients({ bufnr = bufnr })) or vim.lsp.get_active_clients({ bufnr = bufnr })
                        for _, client in pairs(clients) do
                            vim.lsp.buf_attach_client(target_bufnr, client.id)
                        end
                        
                        local retry_err, retry_res = async_req(bufnr, "textDocument/definition", {
                            textDocument = { uri = uri },
                            position = { line = re, character = rec - 1 }
                        })
                        
                        if not retry_err and retry_res and not vim.tbl_isempty(retry_res) then
                            local r_def = retry_res[1] or retry_res
                            local r_uri = r_def.uri or r_def.targetUri
                            local r_range = r_def.range or r_def.targetSelectionRange
                            if r_uri ~= uri or r_range.start.line ~= line then
                                local r_item, r_paths = get_ancestors(r_uri, r_range.start.line, r_range.start.character, visited)
                                if r_item then return r_item, r_paths end
                            end
                        end
                    end
                end
                return nil, {}
            end
            
            -- We found the class, process superclasses
            local name_node = class_node:field("name")[1]
            local sr, sc, er, ec = name_node:range()
            local current_item = {
                name = name, uri = uri,
                range = { start = { line = sr, character = sc }, ["end"] = { line = er, character = ec } }
            }
            
            local parent_paths = {}
            local superclasses = class_node:field("superclasses")[1]
            if superclasses then
                for i = 0, superclasses:named_child_count() - 1 do
                    local child = superclasses:named_child(i)
                    local child_text = vim.treesitter.get_node_text(child, content_str)
                    if child_text ~= "object" then
                        local _, _, e_r, e_c = child:range()
                        
                        local target_bufnr = vim.uri_to_bufnr(uri)
                        vim.fn.bufload(target_bufnr)
                        local clients = (vim.lsp.get_clients and vim.lsp.get_clients({ bufnr = bufnr })) or vim.lsp.get_active_clients({ bufnr = bufnr })
                        for _, client in pairs(clients) do
                            vim.lsp.buf_attach_client(target_bufnr, client.id)
                        end
                        
                        local p_err, p_res = async_req(bufnr, "textDocument/definition", {
                            textDocument = { uri = uri },
                            position = { line = e_r, character = e_c - 1 }
                        })
                        if not p_err and p_res and not vim.tbl_isempty(p_res) then
                            local p_def = p_res[1] or p_res
                            local p_uri = p_def.uri or p_def.targetUri
                            local p_range = p_def.range or p_def.targetSelectionRange
                            
                            local p_item, p_paths = get_ancestors(p_uri, p_range.start.line, p_range.start.character, visited)
                            if p_item then
                                if #p_paths == 0 then
                                    table.insert(parent_paths, { p_item })
                                else
                                    for _, path in ipairs(p_paths) do
                                        table.insert(parent_paths, path)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            local result_paths = {}
            for _, path in ipairs(parent_paths) do
                local new_path = vim.deepcopy(path)
                table.insert(new_path, current_item)
                table.insert(result_paths, new_path)
            end
            if #result_paths == 0 then result_paths = { { current_item } } end
            
            return current_item, result_paths
        end
        
        local target_item, target_paths = get_ancestors(def_uri, def_range.start.line, def_range.start.character, {})
        if not target_item then
            vim.notify("Could not parse class definition.", vim.log.levels.ERROR)
            return
        end
        
        -- Recursively fetches descendant classes by checking textDocument/references
        local function get_subtypes_tree(item, visited)
            visited = visited or {}
            local key = item.uri .. "#" .. item.name
            if visited[key] then return { item = item, children = {} } end
            visited[key] = true
            
            local node_data = { item = item, children = {} }
            local target_bufnr = vim.uri_to_bufnr(item.uri)
            vim.fn.bufload(target_bufnr)
            local clients = (vim.lsp.get_clients and vim.lsp.get_clients({ bufnr = bufnr })) or vim.lsp.get_active_clients({ bufnr = bufnr })
            for _, client in pairs(clients) do
                vim.lsp.buf_attach_client(target_bufnr, client.id)
            end
            
            local r_err, r_res = async_req(bufnr, "textDocument/references", {
                textDocument = { uri = item.uri },
                position = { line = item.range.start.line, character = item.range.start.character },
                context = { includeDeclaration = false }
            })
            
            local seen_subtypes = {}
            if not r_err and r_res and not vim.tbl_isempty(r_res) then
                for _, ref in ipairs(r_res) do
                    local r_uri = ref.uri
                    local ok, r_tree, r_content = pcall(parse_file, vim.uri_to_fname(r_uri))
                    if ok then
                        local r_node = get_node_at_range(r_tree:root(), ref.range)
                        if r_node then
                            -- Ensure the reference we found is actually used as a superclass base
                            local curr = r_node
                            local is_subclass = false
                            while curr do
                                local parent = curr:parent()
                                if parent and parent:type() == "class_definition" then
                                    local sups = parent:field("superclasses")[1]
                                    if sups and sups:id() == curr:id() then
                                        is_subclass = true
                                        curr = parent
                                        break
                                    end
                                end
                                curr = parent
                            end
                            
                            if is_subclass then
                                local sc_name, sc_node = find_enclosing_class(curr, r_content)
                                if sc_name then
                                    local name_node = sc_node:field("name")[1]
                                    local s_r, s_c, e_r, e_c = name_node:range()
                                    local child_key = r_uri .. "#" .. sc_name
                                    if not seen_subtypes[child_key] then
                                        seen_subtypes[child_key] = true
                                        local child_item = {
                                            name = sc_name, uri = r_uri,
                                            range = { start = { line = s_r, character = s_c }, ["end"] = { line = e_r, character = e_c } }
                                        }
                                        table.insert(node_data.children, get_subtypes_tree(child_item, visited))
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return node_data
        end
        
        local target_tree_node = get_subtypes_tree(target_item)
        local lines, targets, target_line_idx = {}, {}, 1
        
        -- Helper for pretty-printing the hierarchy
        local function build_lines(root_node, target_find, is_ancestor_path)
            local function format_node(node, is_last_child, prefix_parts, is_root)
                local item_prefix = ""
                if not is_root then item_prefix = is_last_child and "\\_ " or "|_ " end
                
                local mod_path = get_module_path(vim.uri_to_fname(node.item.uri))
                local mod_suffix = (mod_path and mod_path ~= "") and (" (" .. mod_path .. ")") or ""
                
                local line_str = table.concat(prefix_parts, "") .. item_prefix .. node.item.name .. mod_suffix
                table.insert(lines, line_str)
                table.insert(targets, { uri = node.item.uri, range = node.item.range })
                
                if target_find and node.item.uri == target_find.uri and node.item.name == target_find.name then
                    if not is_ancestor_path then target_line_idx = #lines end
                end
                
                table.sort(node.children, function(a, b) return a.item.name < b.item.name end)
                
                local next_prefix_parts = vim.deepcopy(prefix_parts)
                if not is_root then
                    table.insert(next_prefix_parts, is_last_child and "   " or "|  ")
                end
                
                for i, child in ipairs(node.children) do
                    format_node(child, i == #node.children, next_prefix_parts, false)
                end
            end
            format_node(root_node, true, {}, true)
        end
        
        local target_mod = get_module_path(vim.uri_to_fname(target_item.uri))
        local target_display = target_item.name .. ((target_mod and target_mod ~= "") and (" (" .. target_mod .. ")") or "")
        
        table.insert(lines, "--- Ancestors of " .. target_display .. " ---")
        table.insert(targets, false)
        
        if target_paths and #target_paths > 0 then
            for _, path in ipairs(target_paths) do
                local path_root = { item = path[1], children = {} }
                local curr = path_root
                for i = 2, #path do
                    local child = { item = path[i], children = {} }
                    table.insert(curr.children, child)
                    curr = child
                end
                build_lines(path_root, nil, true)
                table.insert(lines, "")
                table.insert(targets, false)
            end
        else
            table.insert(lines, "  (None)")
            table.insert(targets, false)
            table.insert(lines, "")
            table.insert(targets, false)
        end
        
        table.insert(lines, "--- Descendants of " .. target_display .. " ---")
        table.insert(targets, false)
        target_line_idx = #lines + 1
        
        build_lines(target_tree_node, target_item, false)
        
        table.insert(lines, "")
        table.insert(targets, false)
        table.insert(lines, "  [<CR> Jump]  [<Tab> Add to Quickfix]  [q/Esc Close]")
        table.insert(targets, false)
        
        open_tree_window(lines, targets, target_line_idx)
    end)()
end

return M
