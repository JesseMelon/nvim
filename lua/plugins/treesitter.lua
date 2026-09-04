return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").setup({
            auto_install = true,
        })

        -- New rewrite: highlight is Neovim built-in, enable it per-filetype via autocmd
        vim.api.nvim_create_autocmd("FileType", {
            callback = function(ev)
                local ft = vim.bo[ev.buf].filetype
                -- Skip filetypes where treesitter highlight causes issues
                if ft == "sh" or ft == "bash" then return end
                local ok = pcall(vim.treesitter.start, ev.buf)
                if not ok then
                    -- Parser not available yet, auto_install will handle it on next open
                end
            end,
        })
    end,
}

