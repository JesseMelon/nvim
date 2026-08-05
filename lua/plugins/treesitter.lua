return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    opts = {
        auto_install = true,
        highlight = {
            enable = true,
            disable = { "sh", "bash" },
        },
        indent = {
            enable = true,
            disable = { "cmake", "html" },
        },
    },
}
