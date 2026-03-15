local M = {}

local site_config_dir = os.getenv("HOME") .. "/etc/site"
local function get_site_config(file, default)
    local ok, config = pcall(dofile, site_config_dir .. "/" .. file)
    return ok and config or default
end

-- ty Python LSP server setup
--
-- Discovers the workspace root and virtualenv for each Python buffer, falling
-- back to shebang lines or the default interpreter. Generates deterministic
-- client names so vim.lsp.start() deduplicates correctly.
--
-- ty natively discovers $VIRTUAL_ENV and .venv in the project root, and
-- searches upward for ty.toml/pyproject.toml for configuration. This module
-- adds support for: arbitrarily-named venvs, shebang-based interpreter
-- detection, separate workspace roots for navigating into third-party and
-- stdlib code, and environment inheritance for typeshed stubs.

local excluded_py_paths = get_site_config("nvim-python-excludepaths.lua", {})
local default_py_env = get_site_config("nvim-python-default-exe.lua", nil)
    or vim.fn.exepath("python3")
default_py_env = vim.fn.resolve(default_py_env)

-- Strip /bin/python[3.x] suffix to get the environment prefix
default_py_env = default_py_env:match("^(.+)/bin/python[%d.]*$") or default_py_env

local default_lsp_settings = {
    ty = {
        configuration = {
            environment = { python = default_py_env },
            src = { exclude = excluded_py_paths },
        },
    },
}

local project_markers = { 'ty.toml', 'pyproject.toml', '.git' }
local stop_dirs = { ['/'] = true, ['/usr'] = true, ['/opt'] = true }

local function is_venv(dir)
    return vim.fn.filereadable(dir .. '/pyvenv.cfg') == 1
end

local function has_project_marker(dir)
    for _, marker in ipairs(project_markers) do
        local mark = dir .. '/' .. marker
        if vim.fn.filereadable(mark) == 1 or vim.fn.isdirectory(mark) == 1 then
            return true
        end
    end
    return false
end

local function has_ty_toml(dir)
    return vim.fn.filereadable(dir .. '/ty.toml') == 1
end

--- Scan immediate children of `dir` for virtualenvs.
local function find_child_venvs(dir)
    local found = {}
    local handle = vim.loop.fs_scandir(dir)
    if not handle then return found end
    while true do
        local name, typ = vim.loop.fs_scandir_next(handle)
        if not name then break end
        if typ == 'directory' and is_venv(dir .. '/' .. name) then
            table.insert(found, dir .. '/' .. name)
        end
    end
    return found
end

--- Detect if `fname` is inside a Python environment's lib tree (site-packages
--- or stdlib). Uses path pattern matching to be robust against symlinked venvs.
--- Requires pythonX.Y with major.minor to avoid false positives.
--- Returns: (env_prefix, lib_root) or (nil, nil)
local function detect_python_lib(fname)
    local normalized = vim.fs.normalize(fname)
    if not normalized then return nil, nil end

    for _, p in ipairs({ normalized, vim.fn.resolve(normalized) }) do
        local sp_prefix, py_ver = p:match("^(.+)/lib/(python%d+%.%d+)/site%-packages/")
        if sp_prefix then
            return sp_prefix, sp_prefix .. "/lib/" .. py_ver .. "/site-packages"
        end

        local lib_prefix, lib_pyver = p:match("^(.+)/lib/(python%d+%.%d+)/")
        if lib_prefix then
            return lib_prefix, lib_prefix .. "/lib/" .. lib_pyver
        end
    end
    return nil, nil
end

--- Walk upward from `fname` to discover workspace context.
--- Returns: (project_root, venv_path, has_ty_toml, python_lib_dir)
local function discover_workspace(fname)
    local lib_env, lib_root = detect_python_lib(fname)
    if lib_env then
        return nil, lib_env, false, lib_root
    end

    local path = vim.fs.normalize(fname)
    if not path then return nil, nil, false, nil end
    path = vim.fs.dirname(path)
    if not path then return nil, nil, false, nil end

    local home = vim.env.HOME
    local start_stat = vim.loop.fs_stat(path)
    if not start_stat then return nil, nil, false, nil end
    local start_dev = start_stat.dev

    while path do
        if stop_dirs[path] or path == home then break end

        local stat = vim.loop.fs_stat(path)
        if not stat or stat.dev ~= start_dev then break end

        if is_venv(path) then
            return nil, path, false, nil
        end

        if has_project_marker(path) then
            local child_venvs = find_child_venvs(path)
            if #child_venvs > 1 then
                vim.notify(
                    "[ty] Ambiguous: multiple virtualenvs found in " .. path .. ":\n  "
                        .. table.concat(child_venvs, "\n  ")
                        .. "\nUsing first match: " .. child_venvs[1],
                    vim.log.levels.WARN
                )
            end
            return path, child_venvs[1], has_ty_toml(path), nil
        end

        path = vim.fs.dirname(path)
    end

    return nil, nil, false, nil
end

--- Parse the shebang line, resolve symlinks, and return the canonical path.
local function get_shebang_interpreter(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
    if not lines or #lines == 0 then return nil end
    local line = lines[1]
    if not line:match("^#!") then return nil end

    local path = line:match("^#!%s*/usr/bin/env%s+([^%s]+)")
    if path then
        path = vim.fn.exepath(path)
    else
        path = line:match("^#!%s*([%/][^%s]+)")
    end

    if path and path ~= "" and vim.fn.executable(path) == 1 then
        return vim.fn.resolve(path)
    end
    return nil
end

--- Build environment settings for a venv or installation prefix.
local function env_settings(prefix)
    return { ty = { configuration = { environment = { python = prefix } } } }
end

--- Build environment settings from a shebang interpreter path.
--- Returns (settings, exe_path) or ({}, nil) if the prefix can't be extracted.
local function shebang_settings(shebang)
    local prefix = shebang:match("^(.+)/bin/python[%d.]*$")
    if prefix then
        return env_settings(prefix), shebang
    end
    return {}, nil
end

--- Get the environment and root_dir from the ty client attached to the
--- alternate buffer (the buffer we navigated from via goto-definition etc).
local function get_alternate_ty_env()
    local alt = vim.fn.bufnr('#')
    if alt < 1 then return nil, nil end

    for _, client in ipairs(vim.lsp.get_clients({ bufnr = alt })) do
        if not client.name:match("^ty%-") then goto continue end
        local s = client.config and client.config.settings
        if not s then goto continue end

        local env = s.ty
            and s.ty.configuration
            and s.ty.configuration.environment
            and s.ty.configuration.environment.python
        if env then
            return env, client.config.root_dir
        end
        ::continue::
    end
    return nil, nil
end

M.debug = false

M.setup_ty = function(neovim_venv, lsp_on_attach_cb)
    local python_lsp_group = vim.api.nvim_create_augroup('MyPythonLspStart', { clear = true })

    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'python',
        group = python_lsp_group,
        desc = "Start ty with dynamic interpreter logic",
        callback = function(args)
            local bufnr = args.buf
            local bufname = vim.api.nvim_buf_get_name(bufnr)

            local project_root, venv_path, found_ty_toml, python_lib_dir =
                discover_workspace(bufname)

            -- $VIRTUAL_ENV overrides filesystem venv discovery. We handle this
            -- ourselves rather than relying on ty's native $VIRTUAL_ENV support
            -- because we pass environment.python explicitly, which would
            -- otherwise take precedence over ty's own detection.
            local virtual_env = os.getenv("VIRTUAL_ENV")
            if virtual_env and virtual_env ~= "" then
                venv_path = virtual_env
            end

            local shebang = get_shebang_interpreter(bufnr)

            local root_dir = nil
            local canonical_path = nil
            local dynamic_settings = {}

            if python_lib_dir then
                root_dir = python_lib_dir
                -- Inherit environment from the buffer we navigated from, since
                -- the path-extracted prefix may be the base Python installation
                -- rather than the venv that links to it.
                local alt_env = get_alternate_ty_env()
                dynamic_settings = env_settings(alt_env or venv_path)

            elseif project_root then
                root_dir = project_root
                if found_ty_toml then
                    -- ty.toml present: let ty handle environment resolution
                elseif venv_path then
                    dynamic_settings = env_settings(venv_path)
                elseif shebang then
                    dynamic_settings, canonical_path = shebang_settings(shebang)
                end

            elseif venv_path then
                root_dir = venv_path
                dynamic_settings = env_settings(venv_path)

            elseif shebang then
                root_dir = vim.fn.fnamemodify(bufname, ":h")
                dynamic_settings, canonical_path = shebang_settings(shebang)
            end

            -- No signal (e.g. typeshed stubs): inherit from the alternate
            -- buffer, or fall back to file's directory with default env.
            local inherited_env = false
            if not root_dir then
                local alt_env, alt_root = get_alternate_ty_env()
                if alt_env then
                    dynamic_settings = env_settings(alt_env)
                    inherited_env = true
                end
                root_dir = alt_root or vim.fn.fnamemodify(bufname, ":h")
            end

            local final_settings = vim.tbl_deep_extend(
                "force",
                vim.deepcopy(default_lsp_settings),
                dynamic_settings
            )

            local client_name
            if python_lib_dir or inherited_env then
                client_name = "ty-lib-" .. vim.fn.sha256(root_dir):sub(1, 12)
            elseif project_root then
                client_name = "ty-proj-" .. vim.fn.sha256(root_dir):sub(1, 12)
            elseif canonical_path then
                client_name = "ty-env-" .. vim.fn.sha256(canonical_path):sub(1, 12)
            else
                client_name = "ty-global"
            end

            if M.debug then
                local env = (final_settings.ty
                    and final_settings.ty.configuration
                    and final_settings.ty.configuration.environment
                    and final_settings.ty.configuration.environment.python)
                    or "(default)"
                local resolved = vim.fn.resolve(bufname)
                vim.notify(string.format(
                    "[ty debug] file: %s\n  resolved_file: %s\n"
                    .. "  project_root: %s\n  venv_path: %s\n"
                    .. "  python_lib: %s\n  shebang: %s\n"
                    .. "  root_dir: %s\n  environment: %s\n"
                    .. "  client_name: %s\n  already_running: %s",
                    bufname,
                    resolved ~= bufname and resolved or "(same)",
                    project_root or "(none)",
                    venv_path or "(none)",
                    python_lib_dir or "(none)",
                    shebang or "(none)",
                    root_dir, env, client_name,
                    (function()
                        for _, c in ipairs(vim.lsp.get_clients()) do
                            if c.name == client_name
                                and c.config and c.config.root_dir == root_dir then
                                return "yes"
                            end
                        end
                        return "no"
                    end)()
                ), vim.log.levels.INFO)
            end

            vim.lsp.start({
                name = client_name,
                cmd = { neovim_venv .. "/bin/ty", "server" },
                root_dir = root_dir,
                settings = final_settings,
                on_attach = lsp_on_attach_cb,
            })
        end,
    })
end

return M
