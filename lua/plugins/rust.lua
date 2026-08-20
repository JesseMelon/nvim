return {
    'mrcjkb/rustaceanvim',
    version = '^9',
    lazy = false,
    config = function()
        vim.g.rustaceanvim = {
            server = {
                on_attach = function(client, bufnr)
                    -- Enable Inlay Hints
                    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })

                    -- Auto-format and Refresh Lenses on Save
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = bufnr,
                        callback = function()
                            vim.lsp.buf.format({ bufnr = bufnr })
                            vim.lsp.codelens.refresh()
                        end,
                    })

                    -- Reusable keymap options
                    local opts = { silent = true, buffer = bufnr }

                    -- Keybindings (Using direct table merge instead of unpack)
                    vim.keymap.set("n", "<leader>rr", function()
                        vim.cmd.RustLsp('runnables')
                    end, vim.tbl_extend("force", opts, { desc = "Rust: Run Menu" }))

                    vim.keymap.set("n", "<leader>rc", function()
                        vim.cmd.RustLsp('run')
                    end, vim.tbl_extend("force", opts, { desc = "Rust: Run Current Item" }))

                    vim.keymap.set("n", "<leader>rd", function()
                        vim.cmd.RustLsp('debuggables')
                    end, vim.tbl_extend("force", opts, { desc = "Rust: Debug Menu" }))

                    vim.keymap.set("n", "K", function()
                        vim.cmd.RustLsp({ 'hover', 'actions' })
                    end, vim.tbl_extend("force", opts, { desc = "Rust: Hover Actions" }))
                end,

                settings = function(project_root)
                    local ra = {
                        check = {
                            command = "clippy",
                            extraArgs = { "--no-deps" },
                        },
                        lens = { enable = true },
                        inlayHints = {
                            parameterHints = { enable = true },
                            typeHints = { enable = true },
                        },
                    }
                    local rust_project = project_root .. "/rust-project.json"
                    if vim.fn.filereadable(rust_project) == 1 then
                        ra.linkedProjects = { rust_project }
                    end
                    return { ['rust-analyzer'] = ra }
                end,
            },
        }
    end,
}
