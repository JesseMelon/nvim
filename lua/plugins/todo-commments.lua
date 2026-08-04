return {
    "folke/todo-comments.nvim",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        signs = false,
        highlight = {
            multiline = false,
        }
    },
    keys = {
        { "<leader>st", "<cmd>TodoTelescope<cr>",       desc = "Todo (Telescope)" },
        { "<leader>td", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
    },
}
