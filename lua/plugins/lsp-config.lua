return {

    -- Mason (installer)
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },

    -- Auto-install LSPs
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "clangd",
                    "ast_grep",
                    "html",
                },

                -- You can keep custom handlers for very special cases,
                -- but most can now be removed / simplified
            })
        end,
    },

    -- lspconfig (provides default configs + we override here)
    {
        "neovim/nvim-lspconfig",
        dependencies = { "hrsh7th/cmp-nvim-lsp" }, -- if you're using cmp
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- Modern way: define configs + enable

            -- Example: your special html config
            vim.lsp.config("html", {
                capabilities = capabilities,
                filetypes = { "html" },
                init_options = {
                    provideFormatter = true,
                    configuration = {
                        html = { autoClosingTags = true },
                    },
                    embeddedLanguages = {
                        css = true,
                        javascript = true,
                    },
                },
            })

            vim.lsp.config("clangd", {
                -- Add the cmd table here to override the flags
                cmd = {
                    "clangd",
                    "--background-index=false",
                    "--header-insertion=never",
                    "--completion-style=bundled",
                    "--clang-tidy", -- Keep this if you want those tidy checks from your YAML
                },
                capabilities = capabilities,
                -- Force filetypes here just in case
                filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
            })

            vim.lsp.config("ts_ls", {
                capabilities = capabilities,
                filetypes = {
                    "javascript",
                    "javascriptreact",
                    "javascript.jsx",
                    "typescript",
                    "typescriptreact",
                    "typescript.tsx",
                    "astro",
                },
                init_options = {
                    preferences = {
                        includeCompletionsForModuleExports = true,
                    },
                },
            })

            vim.lsp.config("neocmake", {
                capabilities = capabilities,
                init_options = { command_case = "lower_case", use_snippets = false },
            })

            -- Optional: fallback for all other servers that have default config
            -- (mason-lspconfig already installed them → they'll get auto-enabled with defaults)
            -- You normally don't need to do anything for them anymore

            -- Your global LSP settings & keymaps
            vim.diagnostic.config({
                virtual_text = {
                    format = function(diagnostic)
                        return string.format("%s", diagnostic.message)
                    end,
                },
                signs = true,
                underline = true,
                update_in_insert = false,
                severity_sort = false,
            })

            vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
            vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { noremap = true, silent = true })
        end,
    },
    {
        "stevearc/conform.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            formatters_by_ft = {
                c   = { "clang_format" },
                cpp = { "clang_format" },
                h   = { "clang_format" }, -- headers often treated as C++
                hpp = { "clang_format" },
            },

            formatters = {
                clang_format = {
                    -- Hardcode Linux kernel-like style inline (no .clang-format needed)
                    prepend_args = {
                        '--style={'
                        .. 'BasedOnStyle: LLVM, '
                        .. 'IndentWidth: 8, '
                        .. 'TabWidth: 8, '
                        .. 'UseTab: Always, '
                        .. 'ContinuationIndentWidth: 8, '
                        .. 'BreakBeforeBraces: Linux, '
                        .. 'BreakAfterAttributes: Always, '
                        .. 'ColumnLimit: 80, '          -- your preferred line length
                        .. 'AccessModifierOffset: -8, ' -- flush public:/private: left
                        .. 'PointerAlignment: Left, '
                        .. 'DerivePointerAlignment: false, '
                        .. 'AllowShortFunctionsOnASingleLine: All, '
                        .. 'AllowShortIfStatementsOnASingleLine: true, '
                        .. 'AllowShortLoopsOnASingleLine: false, '
                        .. 'AllowShortBlocksOnASingleLine: false, '
                        .. 'FixNamespaceComments: false, ' -- kernel often disables
                        .. 'SortIncludes: false, '         -- kernel doesn't sort includes aggressively
                        .. 'EmptyLineBeforeAccessModifier: Never'
                        .. '}',
                    },
                },
            },

            -- Format on save (or use :ConformInfo / <leader>cf manually)
            format_on_save = {
                timeout_ms = 750,
                lsp_format = "fallback", -- if LSP has formatter, use it; else conform
            },

            -- Optional: notify when formatting fails
            notify_on_error = true,
        },
    },
}
