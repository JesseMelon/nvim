return {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
        opts = {
            enable_close = true,
            enable_rename = true,
            enable_close_on_slash = false,
        },
        per_filetype = {
            ["astro"] = {
                enable_close = false,
                enable_rename = false,
            }
        }
    },
}
