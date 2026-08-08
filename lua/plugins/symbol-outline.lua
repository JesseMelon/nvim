return {
    "hedyhli/outline.nvim",
    config = function()
        require("outline").setup({})
        vim.keymap.set("n", "<leader>o", "<cmd>Outline<CR>", { noremap = true, silent = true })
    end,
}
