return {
    {
        "shortcuts/no-neck-pain.nvim",
        version = "*",
        opts = {
            width = 120, -- Set the width of your centered buffer
        },
        keys = {
            { "<leader>np", "<cmd>NoNeckPain<cr>", desc = "Toggle Centered Buffer" }
        }
    }
}
