-- Prepend a license header to new files, commented in whatever syntax the
-- buffer's filetype uses.
--
-- SETUP
--   Create a file named .nvim-license in any directory *above* your
--   project (same upward-search rule as .nvim-rsync.json). It holds the
--   bare license text -- no comment markers. Those are added per filetype
--   from 'commentstring', e.g.:
--
--     Licensed under the Apache-2.0 license
--     SPDX-License-Identifier: Apache-2.0
--
-- COMMANDS
--   :LicenseEnable    Auto-prepend to every new file from now on.
--   :LicenseDisable   Stop auto-prepending.
--   :License          Prepend to the current buffer right now.

local M = {}

local CONFIG = '.nvim-license'
local cache = {}

M.enabled = false

-- Nearest CONFIG above the working directory; may sit well above the repo.
local function read_license()
    local file = vim.fs.find(CONFIG, {
        upward = true,
        path = vim.fs.normalize(vim.fn.getcwd()),
        type = 'file',
    })[1]
    if not file then return nil end

    if cache[file] == nil then
        cache[file] = vim.fn.readfile(file)
    end
    return cache[file]
end

local function commented_lines(bufnr)
    local text = read_license()
    if not text then
        vim.notify('no ' .. CONFIG .. ' found', vim.log.levels.WARN)
        return nil
    end

    local commentstring = vim.bo[bufnr].commentstring
    local prefix, suffix = commentstring:match('^(.-)%%s(.*)$')
    if not prefix then
        vim.notify('no commentstring for this filetype', vim.log.levels.WARN)
        return nil
    end

    local out = {}
    for _, line in ipairs(text) do
        if line == '' then
            table.insert(out, '')
        else
            table.insert(out, prefix .. line .. suffix)
        end
    end
    table.insert(out, '')
    return out
end

function M.prepend(bufnr)
    bufnr = bufnr or 0
    local lines = commented_lines(bufnr)
    if not lines then return end
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)
end

vim.api.nvim_create_user_command('License', function()
    M.prepend(0)
end, { desc = 'Prepend the license comment to the current buffer' })

vim.api.nvim_create_user_command('LicenseEnable', function()
    M.enabled = true
    vim.notify('license auto-prepend: on')
end, { desc = 'Auto-prepend the license comment to new files' })

vim.api.nvim_create_user_command('LicenseDisable', function()
    M.enabled = false
    vim.notify('license auto-prepend: off')
end, { desc = 'Stop auto-prepending the license comment' })

-- BufReadPost too: file-tree "add file" commands (e.g. neo-tree) create the
-- file on disk before opening it, so it's an empty *existing* file rather
-- than a BufNewFile.
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
    group = vim.api.nvim_create_augroup('License', { clear = true }),
    callback = function(a)
        if not M.enabled then return end
        if vim.api.nvim_buf_line_count(a.buf) > 1
            or vim.api.nvim_buf_get_lines(a.buf, 0, 1, false)[1] ~= '' then
            return
        end
        -- Deferred: filetype detection's own autocmd (which sets
        -- commentstring) is registered after ours and hasn't run yet here.
        vim.schedule(function() M.prepend(a.buf) end)
    end,
})

return M
