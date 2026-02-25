local M = {}

local ESC = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
local ENTER = vim.api.nvim_replace_termcodes("<Enter>", true, false, true)
local BACKSPACE = vim.api.nvim_replace_termcodes("<BS>", true, false, true)

local function last_index_of(s, ch)
    rstart, rend = s:reverse():find(ch)
    if not rstart then
        return nil
    end

    return #s + 1 - rstart
end

local function next_part(str, indent, maxlinelen, mod, quo)
    local is_fstring = mod:find("f") ~= nil

    local excess_len = math.max(0, #str + indent - maxlinelen)

    if excess_len == 0 then
        return str, nil
    end

    if not is_fstring then
        local part = str:sub(1, #str - excess_len - 1)

        -- If we're too long and we end in a space, need to cut at prev space
        if part:sub(#part) == " " then
            part = part:sub(1, #part - 1)
        end

        local lastspace = last_index_of(part, " ") or (#part - 1)  -- handle no space
        part = part:sub(1, lastspace) .. quo

        local rem = quo .. str:sub(lastspace + 1)

        return part, rem

    else
        local part = str:sub(1, #str - excess_len - 1)

        if part:sub(#part) == " " then
            part = part:sub(1, #part - 1)
        end

        local lastlbrace = last_index_of(part, "{")
        local lastrbrace = last_index_of(part, "}")

        local cut_idx = #str

        if (
            (lastlbrace ~= nil and lastrbrace == nil)
            or (lastlbrace ~= nil and lastrbrace ~= nil and lastlbrace > lastrbrace)
        ) then
            open_quote_idx, _ = str:find(quo)

            if lastlbrace == open_quote_idx + 1 then
                print("interpolated expression is too wide to wrap!")
                return nil, nil
            end

            part = part:sub(1, lastlbrace - 1) .. quo
            local rem = mod .. quo .. str:sub(lastlbrace)

            return part, rem
        else
            local lastspace = last_index_of(part, " ") or (#part - 1)  -- handle no space
            part = part:sub(1, lastspace) .. quo

            local rem = mod .. quo .. str:sub(lastspace + 1)

            return part, rem
        end

    end
end

local function get_py_str_quo(s)
    squo_start, _ = s:find("'")
    if squo_start == nil then
        return '"'
    end

    dquo_start, _ = s:find('"')
    if dquo_start == nil then
        return "'"
    end

    return squo_start < dquo_start and "'" or '"'
end

local function get_py_str_mod(s)
    ch = get_py_str_quo(s)
    quo_idx, _ = s:find(ch)
    return s:sub(1, quo_idx - 1)
end

M.reflow_python_string_on_current_line = function()
    local line = vim.api.nvim_get_current_line()
    local tw = vim.bo.textwidth
    if #line <= tw then
        print("too short to need reflow")
        return
    end

    local _1, _2, pystrexp_start, pystrexp, _3 = line:find("=%s*()(.-)()%s*$")

    vim.cmd('normal! _')
    local indent_spaces = vim.fn.col(".") - 1
    vim.cmd('normal! ' .. pystrexp_start .. '|')

    local pystr_mod = get_py_str_mod(pystrexp)
    local pystr_quo = get_py_str_quo(pystrexp)

    -- move the entire string to its own line
    vim.cmd('normal! i(' .. ENTER)
    vim.cmd('undojoin')
    vim.cmd('normal! o' .. BACKSPACE .. ')')

    if indent_spaces + 4 + #pystrexp <= tw then
        return
    end

    -- if it's still too long, delete it, and write each line individually below
    vim.cmd('normal! kddk')

    local rem = pystrexp
    while rem ~= nil do
        part, rem = next_part(rem, indent_spaces + 4, tw, pystr_mod, pystr_quo)

        vim.cmd('undojoin')
        vim.cmd('normal! o' .. part)
    end
    vim.cmd('undojoin')
end

return M
