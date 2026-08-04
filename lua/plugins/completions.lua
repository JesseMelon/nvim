return {
    {
        "hrsh7th/cmp-nvim-lsp",
    },
    {
        "L3MON4D3/LuaSnip",
        dependencies = {
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },
    },
    {
        "hrsh7th/nvim-cmp",
        config = function()
            local cmp = require("cmp")
            require("luasnip.loaders.from_vscode").lazy_load()

            local first_opt = true --for cycling predictions from second, since first is default

            cmp.setup({
                completion = {
                    keyword_length = 1,
                },
                experimental = {
                    ghost_text = true,
                },
                snippet = {
                    expand = function(args)
                        -- vim.fn["vsnip#anonymous"](args.body) --for 'vsnip'
                        require("luasnip").lsp_expand(args.body) --for luasnip
                        -- require('snippy').expand_snippet(args.body) --for snippy
                        -- vim.fn["UltiSnips#Anon"](args.body) --for ultisnips
                    end,
                },
                window = {
                    completion = cmp.config.window.bordered({
                        winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
                        max_height = 5, -- limit the height of the completion window to 5 lines
                        max_width = 50, -- (optional) limit the width
                    }),
                    documentation = cmp.config.window.bordered({
                        winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
                        max_height = 10, -- limit the height of the documentation window
                    }),
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-l>"] = cmp.mapping(function(fallback)
                        if require("luasnip").jumpable(1) then
                            require("luasnip").jump(1)
                        else
                            local col = vim.api.nvim_win_get_cursor(0)[2] -- Get current column (0-based)
                            local line = vim.api.nvim_get_current_line()  -- Get current line text
                            local closures =
                            { [")"] = true, ["]"] = true, ["}"] = true, ["'"] = true, ['"'] = true, [">"] = true }
                            local moved = false

                            -- hop out of closures
                            while col < #line and closures[line:sub(col + 1, col + 1)] do
                                vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col + 1 })
                                col = col + 1
                                moved = true
                            end
                            if moved == false then
                                fallback()
                            end
                        end
                    end, { "i", "s" }),

                    ["<C-j>"] = cmp.mapping(function(fallback)
                        if require("luasnip").jumpable(-1) then
                            require("luasnip").jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<Esc>"] = cmp.mapping(function(fallback)
                        first_opt = true
                        fallback()
                    end),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            first_opt = true
                            cmp.confirm({ select = true }) -- Confirm selection
                        else
                            fallback()                     -- Insert a normal tab if no completion is available
                        end
                    end, { "i", "s" }),
                    ["<CR>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            first_opt = true
                            cmp.confirm({ select = true }) -- Confirm selection
                        else
                            fallback()                     -- Insert a normal tab if no completion is available
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function()
                        if cmp.visible() then
                            if first_opt then
                                cmp.select_next_item() -- Skip first item on first press
                                cmp.select_next_item()
                                first_opt = false
                            else
                                cmp.select_next_item()
                            end
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    -- { name = "vsnip" },
                    -- { name = "luasnip" }, --luasnip, ultisnips, snippy
                }, {
                    { name = "buffer", keyword_length = 3 },
                }),
            })

            -- -- ┌────────────────────────────────────────────────────────────┐
            -- -- │   THIS BELONGS **OUTSIDE** and **AFTER** cmp.setup()       │
            -- -- └────────────────────────────────────────────────────────────┘
            -- cmp.event:on("confirm_done", function(evt)
            --   vim.notify("confirm_done triggered!", vim.log.levels.INFO)
            --
            --   -- Safely get the completion item (evt.entry can sometimes be nil in edge cases)
            --   local entry = evt and evt.entry
            --   local item = entry and entry:get_completion_item()
            --
            --   if not item then
            --     vim.notify("No completion item found in event!", vim.log.levels.WARN)
            --     return
            --   end
            --
            --   -- Now debug-print safely
            --   vim.notify(
            --     "Kind: " .. tostring(item.kind) .. " | insertTextFormat: " .. tostring(item.insertTextFormat or "nil"),
            --     vim.log.levels.DEBUG
            --   )
            --
            --   -- Try Function kind first (most reliable for cmake-language-server commands)
            --   if vim.bo.filetype == "cmake"
            --      and item.kind == cmp.lsp.CompletionItemKind.Function then
            --
            --     vim.notify("CMake function detected — cleaning parentheses!", vim.log.levels.WARN)
            --
            --     vim.schedule(function()
            --       local keys = vim.api.nvim_replace_termcodes("<Esc>di)", true, false, true)
            --       vim.api.nvim_feedkeys(keys, "n", true)
            --       vim.notify("Parentheses cleaned!", vim.log.levels.INFO)
            --     end)
            --
            --   -- Optional fallback: also catch if somehow it's Snippet (unlikely but good to have)
            --   elseif vim.bo.filetype == "cmake"
            --          and item.kind == cmp.lsp.CompletionItemKind.Snippet then
            --
            --     vim.notify("CMake snippet (rare) detected — cleaning!", vim.log.levels.WARN)
            --     -- same schedule block as above...
            --   end
            -- end)
        end,
    },
}
