local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= -1 then
        vim.api.nvim_echo({
            { "failed to clone lazy.nvim:\n", "errormsg" },
            { out,                            "warningmsg" },
            { "\npress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(0)
    end
end


-- Classic Vim Dark theme with full transparency
-- vim.o.background = "dark"
-- vim.cmd("colorscheme vim")

vim.opt.hlsearch = false
vim.o.equalalways = false

vim.opt.termguicolors = true

-- Force transparency so your cool background shows through
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "NonText", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "FoldColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "VertSplit", { bg = "none" })
vim.api.nvim_set_hl(0, "WinSeparator", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#003344", bg = "none" }) -- subtle border like Kate

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp", "h" }, -- also cover headers
    callback = function()
        vim.opt_local.tabstop     = 8
        vim.opt_local.softtabstop = 8
        vim.opt_local.shiftwidth  = 8
        vim.opt_local.expandtab   = false -- use real tabs
        vim.opt_local.smarttab    = true
        -- Optional but nice for kernel-like feel
        vim.opt_local.cindent     = true
        -- Safely add g0 without concat error
        vim.opt_local.cinoptions:append("g0")
        -- Optional extras for better kernel feel
        -- vim.opt_local.cinoptions:append("l1")  -- case: indented one level
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "lua", "sh", "dosbatch", "cmake" },
    callback = function()
        vim.opt.tabstop = 4
        vim.opt.softtabstop = 4
        vim.opt.shiftwidth = 4
        vim.opt.expandtab = true
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "html", "svg", "xml", "astro", "typescript", "javascript" },
    callback = function()
        vim.opt.tabstop = 2
        vim.opt.softtabstop = 2
        vim.opt.shiftwidth = 2
        vim.opt.expandtab = true
    end,
})

vim.opt.rtp:prepend(lazypath)

vim.opt.relativenumber = true
vim.opt.number = true                  -- Keep the current line's absolute number
vim.opt.formatoptions:remove("r", "o") -- dont auto comment
vim.opt.autoindent = true              -- maintain indentation level
vim.opt.smartindent = true
vim.opt.textwidth = 150;
vim.opt.scrolloff = 5 -- Scroll when 5 lines from the bottom
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set("", "<R-Ctrl>", "<Esc>", { noremap = true, silent = true })

-- vim.keymap.set('n', '<leader>f', ':!astyle --style=java --indent=spaces=4 --max-code-length=150 %<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>#', 'O#<esc>79a=<esc>jo#<esc>79a-<esc>', { noremap = true, silent = true })

vim.opt.clipboard:append("unnamedplus")

vim.cmd([[
let g:clipboard = {
                \   'name': 'WslClipboard',
                \   'copy': {
                \      '+': 'clip.exe',
                \      '*': 'clip.exe',
                \    },
                \   'paste': {
                \      '+': 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
                \      '*': 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
                \   },
                \   'cache_enabled': 0,
                \ }
]])

vim.filetype.add({
    extension = {
        h = "c",     -- Treat .h as C
        hpp = "cpp", -- Treat .hpp as C++ (this is usually default, but good for explicit safety)
    },
})

vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = "*",
    command = "setlocal formatoptions-=cro",
})

-- Astro Indent
vim.api.nvim_create_autocmd("FileType", {
    pattern = "astro",
    callback = function()
        -- 1. Start from the built-in indentkeys (includes / and <>>)
        local ik = vim.opt_local.indentkeys:get()

        -- 2. Remove the two keys that cause the unwanted dedent
        ik = vim.tbl_filter(
            function(k)
                return k ~= "/" and k ~= "<>>" and k ~= "<<>" and k ~= "}" and k ~= "{" and k ~= "0{" and k ~= "<" and
                    k ~= "RETURN"
            end, ik)

        -- 3. Add a *custom* key that runs our Lua function
        table.insert(ik, "<|>")

        vim.opt_local.indentkeys = ik

        -- 4. The function that decides whether to dedent
        vim.opt_local.indentexpr = "v:lua.AstroSmartIndent()"

        -- 5. Define the Lua function (global so indentexpr can see it)
        _G.AstroSmartIndent = function()
            -- local line = vim.fn.getline(".")
            local prev = vim.fn.getline(vim.v.lnum - 1)

            -- If the previous line ends with " />" (space + slash) → keep same indent
            if prev:match("%s+/$") then
                return vim.fn.indent(vim.v.lnum - 1)
            end

            -- Otherwise fall back to Treesitter (or the default Astro indent)
            local ts_indent = vim.treesitter.get_indent and vim.treesitter.get_indent() or -1
            if ts_indent > 0 then
                return ts_indent
            end

            -- Fallback to the original indentexpr (the one from runtime/astro.vim)
            return vim.fn["GetAstroIndent"]()
        end
    end,
})

-- Charcoal background for markdown files only
vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    pattern = { "markdown", "*.md" },
    callback = function()
        if vim.bo.filetype == "markdown" then
            vim.api.nvim_set_hl(0, "Normal", { bg = "#1a1a1a" })
        end
    end,
})
vim.api.nvim_create_autocmd("BufLeave", {
    pattern = { "*.md" },
    callback = function()
        vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    end,
})

require("config.keymaps")

require("lazy").setup("plugins")
