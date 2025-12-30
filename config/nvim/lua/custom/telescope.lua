-- lua/custom/telescope.lua
local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local make_entry = require("telescope.make_entry")
local lsp_utils = require("vim.lsp.util")
local api = vim.api
local lsp_protocol = require("vim.lsp.protocol")

-- Helper to check if a 0-indexed LSP position is inside a 0-indexed LSP range
local function range_contains(range, pos)
  if not range or not range.start or not range["end"] then
    return false
  end

  if pos.line < range.start.line or pos.line > range["end"].line then
    return false
  end

  if pos.line == range.start.line and pos.character < range.start.character then
    return false
  end

  if pos.line == range["end"].line and pos.character > range["end"].character then
    return false
  end

  return true
end

-- Recursively find the symbol scope containing the cursor position
local function find_scope(symbols, pos, parent)
  if not symbols then
    return parent
  end

  for _, s in ipairs(symbols) do
    if range_contains(s.range, pos) then
      -- This symbol contains the cursor
      -- Check if it's a container kind that we can "zoom into"
      local container_kinds = {
        [lsp_protocol.SymbolKind.Class] = true,
        [lsp_protocol.SymbolKind.Module] = true,
        [lsp_protocol.SymbolKind.Struct] = true,
        [lsp_protocol.SymbolKind.Interface] = true,
        [lsp_protocol.SymbolKind.Function] = true,
        [lsp_protocol.SymbolKind.Namespace] = true,
        [lsp_protocol.SymbolKind.Enum] = true,
      }

      if container_kinds[s.kind] and s.children then
        -- It's a container. Recurse into its children
        return find_scope(s.children, pos, s)
      end

      -- It's not a container or has no children
      -- The parent is the scope we want
      return parent
    end
  end

  -- Cursor wasn't in any symbol at this level
  return parent
end

-- Flatten symbol tree recursively
local function flatten_symbols(symbols, bufnr, results, prefix)
  results = results or {}
  prefix = prefix or ""

  if not symbols then
    return results
  end

  for _, symbol in ipairs(symbols) do
    local entry = {
      kind = symbol.kind,
      name = symbol.name,
      range = symbol.range,
      selectionRange = symbol.selectionRange,
      detail = symbol.detail,
      display_name = prefix .. symbol.name,
      filename = api.nvim_buf_get_name(bufnr),
    }

    table.insert(results, entry)

    -- Recursively add children
    if symbol.children and #symbol.children > 0 then
      flatten_symbols(symbol.children, bufnr, results, prefix .. symbol.name .. ".")
    end
  end

  return results
end

-- Create entry maker for telescope (matching builtin lsp_document_symbols format)
local function make_symbol_entry(opts)
  opts = opts or {}
  local bufnr = opts.bufnr or api.nvim_get_current_buf()

  -- Use Telescope's builtin entry maker for LSP document symbols
  -- This will properly display the kind on the right side
  -- Try different possible module paths
  local builtin_utils = nil
  local ok1, utils1 = pcall(require, "telescope.builtin.lsp.utils")
  local ok2, utils2 = pcall(require, "telescope.builtin.lsp")

  if ok1 and utils1 then
    builtin_utils = utils1
  elseif ok2 and utils2 then
    builtin_utils = utils2
  end

  if builtin_utils then
    -- Try different possible function names
    if builtin_utils.make_entry_from_lsp_symbol then
      return builtin_utils.make_entry_from_lsp_symbol(bufnr, opts)
    elseif builtin_utils.gen_from_lsp_symbols then
      return builtin_utils.gen_from_lsp_symbols(bufnr, opts)
    end
  end

  -- Fallback: create our own entry maker that formats display with kind on right
  return function(entry)
    local filename = api.nvim_buf_get_name(bufnr)
    local kind = entry.kind or lsp_protocol.SymbolKind.File

    -- Get kind name for display
    local kind_name = lsp_protocol.SymbolKind[kind] or "Unknown"

    -- Ensure range exists and has valid structure
    local lnum = 1
    local col = 0
    if entry.range and entry.range.start then
      lnum = entry.range.start.line + 1  -- Convert 0-indexed to 1-indexed
      col = math.max(0, entry.range.start.character)  -- Keep 0-indexed, ensure non-negative
    elseif entry.selectionRange and entry.selectionRange.start then
      lnum = entry.selectionRange.start.line + 1
      col = math.max(0, entry.selectionRange.start.character)
    end

    -- Format entry to match Telescope's builtin format
    -- Manually format display with kind on the right (like builtin does)
    local display_str = entry.name
    if entry.detail then
      display_str = display_str .. " " .. entry.detail
    end

    -- Get the display width for padding (default to 80, but can be configured)
    local display_width = opts.display_width or 80

    -- Format: name on left, kind on right (padded)
    -- This matches Telescope's builtin lsp_document_symbols format
    local padded_display = display_str
    local kind_str = kind_name
    if #padded_display + #kind_str + 2 < display_width then
      local padding = display_width - #padded_display - #kind_str
      padded_display = padded_display .. string.rep(" ", padding) .. kind_str
    else
      padded_display = display_str .. "  " .. kind_str
    end

    return {
      value = entry,
      display = padded_display,
      ordinal = entry.name,
      filename = filename,
      lnum = lnum,
      col = col,
      kind = kind,
      kind_name = kind_name,
      -- Include the full symbol for compatibility
      symbol = entry,
    }
  end
end

-- Find symbols in current context (class/function containing cursor)
M.lsp_context_symbols = function(opts)
  opts = opts or {}
  local bufnr = api.nvim_get_current_buf()

  -- Get cursor position (1-indexed) and convert to 0-indexed for LSP
  local pos = api.nvim_win_get_cursor(0)
  local lsp_pos = { line = pos[1] - 1, character = pos[2] }

  -- Use vim.lsp.buf_request which automatically picks clients that support the method
  -- This is the same approach Telescope's builtin uses
  local params = {
    textDocument = {
      uri = vim.uri_from_bufnr(bufnr)
    }
  }

  -- Request document symbols - buf_request will query all clients that support it
  vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result, ctx, config)
    if err then
      vim.notify("LSP error: " .. vim.inspect(err), vim.log.levels.ERROR)
      return
    end

    if not result then
      vim.notify("No symbols returned from LSP", vim.log.levels.WARN)
      return
    end

    -- Handle both SymbolInformation[] and DocumentSymbol[] formats
    if type(result) ~= "table" or #result == 0 then
      vim.notify("No symbols found in file", vim.log.levels.INFO)
      return
    end

    -- Find the scope containing the cursor (class/struct/enum)
    local dummy_root = { children = result }
    local scope_node = find_scope(result, lsp_pos, dummy_root)

    -- Get symbols to display (children of the scope)
    local symbols_to_display = {}
    if scope_node and scope_node.children then
      -- Filter to only show methods/functions, not variables, properties, etc.
      local method_kinds = {
        [lsp_protocol.SymbolKind.Method] = true,
        [lsp_protocol.SymbolKind.Function] = true,
        [lsp_protocol.SymbolKind.Constructor] = true,
      }

      for _, symbol in ipairs(scope_node.children) do
        if method_kinds[symbol.kind] then
          table.insert(symbols_to_display, symbol)
        end
      end
    end

    if #symbols_to_display == 0 then
      vim.notify("No methods found in current class/struct/enum", vim.log.levels.INFO)
      return
    end

    -- Create entries for ONLY the methods themselves (no children, no parameters/variables)
    -- Format as DocumentSymbol objects for Telescope's builtin entry maker
    local flat_symbols = {}
    for _, symbol in ipairs(symbols_to_display) do
      -- Create a DocumentSymbol-like structure
      table.insert(flat_symbols, {
        kind = symbol.kind,
        name = symbol.name,
        range = symbol.range,
        selectionRange = symbol.selectionRange or symbol.range,
        detail = symbol.detail,
        -- Keep the full symbol structure for Telescope's entry maker
      })
    end

    -- Create the picker
    opts.bufnr = bufnr
    pickers.new(opts, {
      prompt_title = "LSP Methods (Current Class)",
      finder = finders.new_table({
        results = flat_symbols,
        entry_maker = make_symbol_entry(opts),
      }),
      previewer = conf.qflist_previewer(opts),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection and selection.lnum and selection.col then
            -- col is already 0-indexed, lnum is 1-indexed
            api.nvim_win_set_cursor(0, { selection.lnum, selection.col })
          end
        end)
        return true
      end,
    }):find()
  end)
end

-- Find only classes in the current file
M.lsp_classes = function(opts)
  opts = opts or {}
  local bufnr = api.nvim_get_current_buf()

  -- Use vim.lsp.buf_request which automatically picks clients that support the method
  -- This is the same approach Telescope's builtin uses
  local params = {
    textDocument = {
      uri = vim.uri_from_bufnr(bufnr)
    }
  }

  -- Request document symbols - buf_request will query all clients that support it
  vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result, ctx, config)
    if err then
      vim.notify("LSP error: " .. vim.inspect(err), vim.log.levels.ERROR)
      return
    end

    if not result then
      vim.notify("No symbols returned from LSP", vim.log.levels.WARN)
      return
    end

    -- Handle both SymbolInformation[] and DocumentSymbol[] formats
    if type(result) ~= "table" or #result == 0 then
      vim.notify("No symbols found in file", vim.log.levels.INFO)
      return
    end

    -- Filter to only show container types (classes, structs, enums, etc.)
    -- but NOT functions, variables, methods, etc.
    local container_kinds = {
      [lsp_protocol.SymbolKind.Class] = true,
      [lsp_protocol.SymbolKind.Struct] = true,
      [lsp_protocol.SymbolKind.Interface] = true,
      [lsp_protocol.SymbolKind.Enum] = true,
      [lsp_protocol.SymbolKind.Module] = true,
      [lsp_protocol.SymbolKind.Namespace] = true,
    }

    local containers_only = {}
    for _, symbol in ipairs(result) do
      if container_kinds[symbol.kind] then
        table.insert(containers_only, symbol)
      end
    end

    if #containers_only == 0 then
      vim.notify("No classes/structs/enums found in file", vim.log.levels.INFO)
      return
    end

    -- Create entries for ONLY the container types themselves (no children)
    -- Filter to only Class, Struct, or Enum (not Module, Namespace, Interface)
    local strict_container_kinds = {
      [lsp_protocol.SymbolKind.Class] = true,
      [lsp_protocol.SymbolKind.Struct] = true,
      [lsp_protocol.SymbolKind.Enum] = true,
    }

    local strict_containers = {}
    for _, symbol in ipairs(containers_only) do
      if strict_container_kinds[symbol.kind] then
        table.insert(strict_containers, symbol)
      end
    end

    if #strict_containers == 0 then
      vim.notify("No classes/structs/enums found in file", vim.log.levels.INFO)
      return
    end

    -- Create entries for just the container symbols themselves (no children, no flattening)
    -- Format as DocumentSymbol objects for Telescope's builtin entry maker
    local flat_symbols = {}
    for _, symbol in ipairs(strict_containers) do
      -- Create a DocumentSymbol-like structure
      table.insert(flat_symbols, {
        kind = symbol.kind,
        name = symbol.name,
        range = symbol.range,
        selectionRange = symbol.selectionRange or symbol.range,
        detail = symbol.detail,
        -- Keep the full symbol structure for Telescope's entry maker
      })
    end

    -- Create the picker
    opts.bufnr = bufnr
    pickers.new(opts, {
      prompt_title = "LSP Classes/Structs/Enums (Current File)",
      finder = finders.new_table({
        results = flat_symbols,
        entry_maker = make_symbol_entry(opts),
      }),
      previewer = conf.qflist_previewer(opts),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection and selection.lnum and selection.col then
            -- col is already 0-indexed, lnum is 1-indexed
            api.nvim_win_set_cursor(0, { selection.lnum, selection.col })
          end
        end)
        return true
      end,
    }):find()
  end)
end

return M
