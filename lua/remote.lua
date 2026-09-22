-- Push a local project to a remote machine with rsync, for editing here and
-- building there.
--
-- SETUP
--   Create a file named .nvim-rsync.json in any directory *above* your project.
--   Putting it in the parent of your repo keeps it out of version control, so
--   it never needs gitignoring and can describe several projects at once.
--
--   Starting from nvim's working directory (:pwd -- i.e. where you launched
--   nvim, not the file you are editing), the nearest such file going upward is
--   the one used.
--
--   {
--       "remotes": [
--           {
--               "host":        "build-box.example.com",
--               "local_path":  "/home/me/dev/myproject",
--               "remote_path": "/scratch/me/myproject",
--               "exclude":     ["/out/", "/bazel-*"]
--           }
--       ]
--   }
--
--   host         ssh destination. Must work as `ssh <host>` with no password,
--                so run `ssh-copy-id <host>` first -- a password prompt has
--                nowhere to appear from inside nvim and will just hang.
--   local_path   Absolute path of the project here. This decides BOTH which
--                entry applies (the one containing your working directory) and
--                what gets sent. Required.
--   remote_path  Absolute path on the far side. Its parent must already exist.
--   exclude      Optional rsync patterns. A leading "/" anchors to the project
--                root, so "/out/" skips only the top-level out directory.
--
--   List several entries to cover several projects, or the same project on
--   several machines. When more than one entry matches, :Rsync asks which.
--
-- IMPORTANT
--   The transfer uses --delete: the remote becomes a mirror, so anything there
--   that is not here is removed. .gitignore is deliberately NOT consulted,
--   since ignored files are often generated build inputs the remote needs --
--   which also means .git/ is synced unless you exclude it. Preview any of
--   this with `rsync -avn --delete ...` before the first real run.
--
-- COMMANDS
--   :Rsync [host]   Sync now; completes configured hosts.
--   :RsyncLog       Show the file list from the last sync.
--   :RsyncAuto      Toggle syncing on every save (off by default).

local M = {}

local CONFIG = '.nvim-rsync.json'
local cache, busy, chosen = {}, {}, {}

M.auto = false

-- Nearest CONFIG above the working directory; may sit well above the repo.
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

-- Remotes whose local_path contains the working directory.
local function applicable()
    local conf, file = read_config()
    if not conf then return nil end
    local name = vim.fs.normalize(vim.fn.getcwd())
    local out = {}
    for _, r in ipairs(conf.remotes or {}) do
        local root = r.local_path and vim.fs.normalize(r.local_path)
        if root and (name == root or name:sub(1, #root + 1) == root .. '/') then
            table.insert(out, r)
        end
    end
    return out, file
end

local function by_host(list, host)
    for _, r in ipairs(list) do
        if r.host == host then return r end
    end
end

local function rsync(remote, verbose)
    local root = vim.fs.normalize(remote.local_path)
    local key = root .. '\0' .. remote.host
    if busy[key] then
        busy[key] = 'again'
        return
    end
    busy[key] = true

    local ssh = table.concat({
        'ssh',
        '-o', 'ControlMaster=auto',
        '-o', 'ControlPath=' .. vim.env.HOME .. '/.ssh/cm-%r@%h:%p',
        '-o', 'ControlPersist=10m',
    }, ' ')

    local args = { 'rsync', '-az', '--delete', '--out-format=%o %n' }
    for _, pat in ipairs(remote.exclude or {}) do
        table.insert(args, '--exclude')
        table.insert(args, pat)
    end
    vim.list_extend(args, {
        '-e', ssh,
        root .. '/',
        remote.host .. ':' .. remote.remote_path .. '/',
    })

    if verbose then
        vim.notify('rsync -> ' .. remote.host .. ' ...')
    end
    local started = vim.uv.hrtime()

    vim.system(args, { text = true }, function(res)
        local again = busy[key] == 'again'
        busy[key] = nil
        local elapsed = (vim.uv.hrtime() - started) / 1e9
        vim.schedule(function()
            if res.code ~= 0 then
                vim.notify('rsync ' .. remote.host .. ': ' .. (res.stderr or ''), vim.log.levels.ERROR)
            else
                M.log = vim.split(res.stdout or '', '\n', { trimempty = true })
                local sent, deleted = 0, 0
                for _, line in ipairs(M.log) do
                    if line:match('/$') then         -- directory entry, not a file
                    elseif line:match('^del%.') then
                        deleted = deleted + 1
                    elseif line:match('^send ') then
                        sent = sent + 1
                    end
                end
                vim.notify(string.format('%s: %d sent, %d deleted, %.1fs  (:RsyncLog)',
                    remote.host, sent, deleted, elapsed))
            end
            if again then rsync(remote, false) end
        end)
    end)
end

function M.sync(arg)
    local list, file = applicable()
    if not list then
        vim.notify('no ' .. CONFIG .. ' found', vim.log.levels.WARN)
        return
    end
    if #list == 0 then
        vim.notify(CONFIG .. ': no remote covers this file', vim.log.levels.WARN)
        return
    end

    if arg and arg ~= '' then
        local r = by_host(list, arg)
        if not r then
            vim.notify('unknown remote: ' .. arg, vim.log.levels.ERROR)
            return
        end
        chosen[file] = r.host
        return rsync(r, true)
    end

    if #list == 1 then
        chosen[file] = list[1].host
        return rsync(list[1], true)
    end

    vim.ui.select(list, {
        prompt = 'rsync to:',
        format_item = function(r) return r.host .. '   ' .. r.remote_path end,
    }, function(r)
        if not r then return end
        chosen[file] = r.host
        rsync(r, true)
    end)
end

vim.api.nvim_create_user_command('Rsync', function(a) M.sync(a.args) end, {
    nargs = '?',
    complete = function(lead)
        local list = applicable()
        if not list then return {} end
        local out = {}
        for _, r in ipairs(list) do
            if r.host:find(lead, 1, true) == 1 then table.insert(out, r.host) end
        end
        return out
    end,
})

vim.api.nvim_create_user_command('RsyncLog', function()
    if not M.log or #M.log == 0 then
        vim.notify('nothing synced yet')
        return
    end
    vim.cmd('botright new')
    vim.bo.buftype = 'nofile'
    vim.bo.bufhidden = 'wipe'
    vim.bo.swapfile = false
    vim.api.nvim_buf_set_lines(0, 0, -1, false, M.log)
end, {})

vim.api.nvim_create_user_command('RsyncAuto', function()
    M.auto = not M.auto
    vim.notify('rsync on save: ' .. (M.auto and 'on' or 'off'))
end, {})

vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup('RemoteSync', { clear = true }),
    callback = function(a)
        if vim.fn.fnamemodify(a.file, ':t') == CONFIG then
            cache = {}
            return
        end
        if not M.auto then return end
        local list, file = applicable()
        if not list or #list == 0 then return end
        local remote = (chosen[file] and by_host(list, chosen[file]))
            or (#list == 1 and list[1])
            or nil
        if remote then rsync(remote, false) end
    end,
})

return M
