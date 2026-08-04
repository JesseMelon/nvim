---@diagnostic disable: undefined-global
local lush = require("lush")
local hsl = lush.hsl

local theme = lush(function()
    return {
        -- Base transparent background
        Normal { bg = "none", fg = hsl(0, 0, 78) },     -- Light grey text #c6c6c6
        NormalNC { bg = "none" },
        NonText { bg = "none", fg = hsl(160, 40, 40) }, -- Emerald tint for non-text
        EndOfBuffer { bg = "none", fg = hsl(160, 40, 40) },
        SignColumn { bg = "none" },
        FoldColumn { bg = "none" },
        NormalFloat { bg = hsl(160, 20, 10) },
        FloatBorder { fg = hsl(180, 60, 60), bg = "none" }, -- Teal border

        -- Syntax groups
        Comment { fg = hsl(160, 90, 30), gui = "italic" }, -- Emerald green comments #1ad99f
        Constant { fg = hsl(160, 60, 50) },                -- Pink constants #ff87ff
        Number { fg = hsl(300, 100, 76) },                 -- Pink numbers
        Float { fg = hsl(200, 100, 60) },
        Boolean { fg = hsl(0, 80, 100) },
        Character { fg = hsl(300, 100, 76) },             -- Pink chars

        String { fg = hsl(140, 80, 60) },                 -- Brighter green strings #66e866

        Identifier { fg = hsl(0, 0, 78) },                -- Light grey variables
        Function { fg = hsl(0, 0, 78) },                  -- Light grey functions

        Statement { fg = hsl(40, 50, 46), gui = "bold" }, -- Orangey gold bold for statements
        Conditional { Statement },                        -- Control flow: if/else
        Repeat { Statement },                             -- loops
        Label { Statement },
        Exception { Statement },

        Operator { Statement },            -- Light grey operators

        PreProc { fg = hsl(160, 60, 50) }, -- Teal for #includes #5fd7d7
        Keyword { PreProc },               -- keywords
        Include { PreProc },
        Define { PreProc },
        Macro { PreProc },
        PreCondit { PreProc },

        Type { fg = hsl(180, 60, 60), gui = "bold" }, -- Teal bold types
        StorageClass { Type },
        Structure { Type },
        Typedef { Type },

        Special { fg = hsl(180, 100, 70) }, -- Lighter teal special
        SpecialChar { Special },
        Tag { Special },
        Delimiter { fg = hsl(280, 45, 55) },
        SpecialComment { Comment },
        Debug { Special },

        Underlined { gui = "underline" },
        Ignore { fg = hsl(0, 0, 40) },
        Error { fg = hsl(0, 80, 60), gui = "bold,underline" }, -- Red error
        Todo { fg = hsl(40, 100, 76), gui = "bold" },          -- Gold todo

        -- UI elements with foresty vibes
        CursorLine { bg = "none" },                           -- No bg for transparency
        CursorLineNr { fg = hsl(160, 80, 60), gui = "bold" }, -- Emerald current line nr
        LineNr { fg = hsl(160, 60, 50) },                     -- Teal line numbers

        Visual { bg = hsl(160, 30, 20) },                     -- Subtle dark green selection
        VisualNOS { Visual },

        Search { fg = "none", bg = hsl(40, 60, 30), gui = "bold" }, -- Gold search
        IncSearch { fg = "none", bg = hsl(40, 80, 40), gui = "bold" },
        CurSearch { IncSearch },

        StatusLine { fg = hsl(160, 80, 50), bg = hsl(180, 60, 2), gui = "bold" }, -- Emerald statusline
        StatusLineNC { fg = hsl(160, 60, 50), bg = hsl(300, 0, 1) },
        WinSeparator { fg = hsl(180, 60, 60), bg = "none" },                      -- Teal separators
        VertSplit { WinSeparator },

        TabLine { fg = hsl(0, 0, 78), bg = "none" },
        TabLineFill { bg = "none" },
        TabLineSel { fg = hsl(160, 80, 50), gui = "bold" },

        Title { fg = hsl(160, 80, 50), gui = "bold" },
        Directory { fg = hsl(180, 60, 60), gui = "bold" },

        -- Diff
        DiffAdd { fg = hsl(120, 60, 60), bg = "none" },
        DiffChange { fg = hsl(40, 60, 60), bg = "none" },
        DiffDelete { fg = hsl(0, 60, 60), bg = "none" },
        DiffText { fg = hsl(180, 60, 60), bg = "none" },

        -- Spell
        SpellBad { gui = "undercurl", sp = hsl(0, 80, 60) },
        SpellCap { gui = "undercurl", sp = hsl(180, 60, 60) },
        SpellLocal { gui = "undercurl", sp = hsl(120, 60, 60) },
        SpellRare { gui = "undercurl", sp = hsl(300, 60, 60) },

        -- Pmenu (completion)
        Pmenu { fg = hsl(0, 0, 78), bg = hsl(160, 20, 10) },
        PmenuSel { fg = hsl(160, 80, 50), bg = hsl(160, 20, 20) },
        PmenuSbar { bg = hsl(160, 20, 20) },
        PmenuThumb { bg = hsl(160, 80, 50) },

        -- QuickFix
        QuickFixLine { bg = hsl(40, 30, 20) },

        -- NeoTree customizations - foresty
        NeoTreeNormal { bg = "none" },
        NeoTreeNormalNC { bg = "none" },
        NeoTreeFileName { fg = hsl(180, 60, 60) },                     -- Teal files
        NeoTreeFileNameOpened { fg = hsl(160, 80, 50), gui = "bold" }, -- Emerald opened
        NeoTreeRootName { fg = hsl(160, 80, 50), gui = "bold" },
        NeoTreeDirectoryName { fg = hsl(160, 80, 50) },                -- Emerald directories
        NeoTreeDirectoryIcon { fg = hsl(160, 80, 50) },
        NeoTreeGitIgnored { fg = hsl(280, 20, 55) },                   -- Darker emerald ignored
        NeoTreeIndentMarker { fg = hsl(180, 40, 40) },                 -- Teal indent
        NeoTreeFloatBorder { fg = hsl(180, 60, 60) },
        NeoTreeTitleBar { fg = hsl(160, 80, 50) },

        -- Telescope
        TelescopeBorder { fg = hsl(180, 60, 60) }, -- Teal border
        TelescopeNormal { bg = "none" },
        TelescopeSelection { fg = hsl(160, 80, 50), gui = "bold" },

        -- Other common groups to cover
        ColorColumn { bg = hsl(160, 20, 20) },
        Conceal { fg = hsl(0, 0, 50) },
        Cursor { fg = hsl(0, 0, 0), bg = hsl(160, 80, 50) },
        CursorColumn { bg = "none" },
        ErrorMsg { fg = hsl(0, 80, 60), bg = "none" },
        Folded { fg = hsl(160, 40, 40), bg = "none" },
        MatchParen { fg = hsl(50, 100, 76), gui = "bold,underline" },
        ModeMsg { fg = hsl(160, 80, 50) },
        MoreMsg { fg = hsl(120, 60, 60) },
        Question { fg = hsl(40, 100, 76) },
        SpecialKey { fg = hsl(180, 40, 40) },
        WarningMsg { fg = hsl(40, 80, 60) },
        WildMenu { fg = hsl(160, 80, 50), bg = hsl(160, 20, 20) },
        DiagnosticInfo { fg = hsl(300, 60, 76), bg = hsl(300, 60, 76) },


        -- Language-specific (to prevent defaults)
        htmlTagName { fg = hsl(180, 60, 60) },
        htmlArg { fg = hsl(0, 0, 78) },
        cssProp { fg = hsl(40, 100, 76) },
        cssAttr { fg = hsl(300, 100, 76) },
        jsFunction { fg = hsl(0, 0, 78) },
        jsOperator { fg = hsl(0, 0, 78) },
        jsonKeyword { fg = hsl(180, 60, 60) },
        luaFunction { fg = hsl(0, 0, 78) },
        luaTable { fg = hsl(40, 100, 76) },
        markdownCode { fg = hsl(140, 80, 60) },
        texStatement { fg = hsl(40, 100, 76) },
        vimCommand { fg = hsl(180, 60, 60) },
        yamlKey { fg = hsl(180, 60, 60) },
    }
end)

return theme
