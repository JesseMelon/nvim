-- Regenerate a project's editor index (rust-project.json, compile_commands.json,
-- build.zig.zon metadata, ...) with a project-defined command, then optionally
-- tell the LSP to reload.
--
-- SETUP
--   Create a file named .nvim-projgen.json in any directory *above* your
--   project (the same place you'd put .nvim-rsync.json). Starting from nvim's
--   working directory (:pwd), the nearest such file going upward is the one
--   used.
--
--   {
--       "generators": [
--           {
--               "local_path": "/home/me/dev/myproject",
--               "cmd":        ["bazelisk", "run", "@rules_rust//tools/rust_analyzer:gen_rust_project", "--", "//..."],
--               "reload":     "RustLsp reloadWorkspace"
--           }
--       ]
--   }
--
--   local_path   Absolute path of the project. Decides which entry applies
--                (the one containing your working directory). Required.
--   cmd          Argv to run, as a list of strings (no shell involved).
--                Required.
--   cwd          Directory to run cmd in. Optional, defaults to local_path.
--   reload       Optional Ex command (without the leading ":") run after cmd
--                exits successfully, e.g. "RustLsp reloadWorkspace" or
--                "LspRestart". Omit if nothing needs telling.
--
--   List several entries to cover several projects. When more than one entry
--   matches, :GenProject asks which.
--
-- COMMANDS
--   :GenProject [local_path]   Run the generator now; completes matching entries.
--   <leader>rg                 Same, via keymap.

local M = {}

local CONFIG = '.nvim-projgen.json'
local cache = {}
local busy = {}

local function read_config()
    local file = vim.fs.find(CONFIG, {
        upward = true,
        path = vim.fs.normalize(vim.fn.getcwd()),
        type = 'file',
    })[1]
    if not file then return nil end

    if cache[file] == nil then
        local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(file), '\n'))
        if not ok then
            vim.notify(file .. ': invalid JSON', vim.log.levels.ERROR)
            return nil
        end
        cache[file] = decoded
    end
    return cache[file], file
end

-- Generators whose local_path contains the working directory.
local function applicable()
    local conf, file = read_config()
    if not conf then return nil end
    local name = vim.fs.normalize(vim.fn.getcwd())
    local out = {}
    for _, g in ipairs(conf.generators or {}) do
        local root = g.local_path and vim.fs.normalize(g.local_path)
        if root and (name == root or name:sub(1, #root + 1) == root .. '/') then
            table.insert(out, g)
        end
    end
    return out, file
end

-- reload commands like :RustLsp are buffer-local (created only on buffers
-- the relevant LSP has attached to), so the invoking buffer is just the
-- first guess. Fall back to any other loaded buffer under the project root
-- that actually accepts the command.
local function do_reload(root, first_bufnr, reload)
    local candidates = { first_bufnr }
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= first_bufnr and vim.api.nvim_buf_is_loaded(buf) then
            local name = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
            if name ~= '' and (name == root or name:sub(1, #root + 1) == root .. '/') then
                table.insert(candidates, buf)
            end
        end
    end
    for _, buf in ipairs(candidates) do
        if vim.api.nvim_buf_is_valid(buf) then
            local ok = pcall(vim.api.nvim_buf_call, buf, function() vim.cmd(reload) end)
            if ok then return true end
        end
    end
    return false
end

local function run(gen)
    if not gen.cmd or #gen.cmd == 0 then
        vim.notify(CONFIG .. ': generator has no cmd', vim.log.levels.ERROR)
        return
    end
    local cwd = vim.fs.normalize(gen.cwd or gen.local_path)
    if busy[cwd] then return end
    busy[cwd] = true

    local bufnr = vim.api.nvim_get_current_buf()
    local root = vim.fs.normalize(gen.local_path)

    vim.notify('Regenerating (' .. table.concat(gen.cmd, ' ') .. ') ...')

    vim.system(gen.cmd, { cwd = cwd }, vim.schedule_wrap(function(obj)
        busy[cwd] = nil
        if obj.code ~= 0 then
            vim.notify(
                'gen failed (exit ' .. obj.code .. '):\n' .. (obj.stderr or ''),
                vim.log.levels.ERROR
            )
            return
        end
        vim.notify('Regenerated' .. (gen.reload and ', reloading' or ''))
        if gen.reload and not do_reload(root, bufnr, gen.reload) then
            vim.notify(gen.reload .. ': no open buffer accepted this command', vim.log.levels.WARN)
        end
    end))
end

function M.gen(arg)
    local list, file = applicable()
    if not list then
        vim.notify('no ' .. CONFIG .. ' found', vim.log.levels.WARN)
        return
    end
    if #list == 0 then
        vim.notify(CONFIG .. ': no generator covers this directory', vim.log.levels.WARN)
        return
    end

    if arg and arg ~= '' then
        for _, g in ipairs(list) do
            if g.local_path == arg then return run(g) end
        end
        vim.notify('unknown generator: ' .. arg, vim.log.levels.ERROR)
        return
    end

    if #list == 1 then
        return run(list[1])
    end

    vim.ui.select(list, {
        prompt = 'regenerate:',
        format_item = function(g) return g.local_path .. '   ' .. table.concat(g.cmd, ' ') end,
    }, function(g)
        if g then run(g) end
    end)
end

vim.api.nvim_create_user_command('GenProject', function(a) M.gen(a.args) end, {
    nargs = '?',
    complete = function(lead)
        local list = applicable()
        if not list then return {} end
        local out = {}
        for _, g in ipairs(list) do
            if g.local_path:find(lead, 1, true) == 1 then table.insert(out, g.local_path) end
        end
        return out
    end,
})

vim.keymap.set('n', '<leader>rg', function() M.gen() end, { desc = 'Regenerate project index' })

vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup('GenProjectConfig', { clear = true }),
    callback = function(a)
        if vim.fn.fnamemodify(a.file, ':t') == CONFIG then
            cache = {}
        end
    end,
})

return M
