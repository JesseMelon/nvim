return {
  "cvlmtg/inline-diff.nvim",
  config = function()
    local inline = require("inline-diff")
    inline.setup()

    -- Override the renderer so changed hunks show all removed (red) lines as one
    -- contiguous block, followed by all added (yellow) lines, instead of
    -- interleaving them old-above-new pair-by-pair (the "stripes"). Patched here
    -- rather than in the plugin source so it survives updates.
    local render = require("inline-diff.render")
    local diff = require("inline-diff.diff")
    local state = require("inline-diff.state")

    render.apply = function(bufnr, ns, hunks)
      render.clear(bufnr, ns)

      local set_extmark = vim.api.nvim_buf_set_extmark
      local last_row = vim.api.nvim_buf_line_count(bufnr) - 1

      local s = state._bufs[bufnr]
      if s then
        s.has_top_virt = false
        s.has_bot_virt = false
      end

      for _, hunk in ipairs(hunks) do
        if hunk.old_count == 0 then
          -- Pure addition
          for i = 1, hunk.new_count do
            local line_idx = hunk.new_start - 1 + (i - 1)
            set_extmark(bufnr, ns, line_idx, 0, {
              end_col = #(hunk.new_lines[i] or ""),
              hl_group = "InlineDiffAdd",
              hl_eol = true,
              priority = 200,
            })
          end
        elseif hunk.new_count == 0 then
          -- Pure deletion
          local virt_lines = {}
          for _, old_line in ipairs(hunk.old_lines) do
            virt_lines[#virt_lines + 1] = { { old_line, "InlineDiffDelete" } }
          end
          if hunk.new_start == 0 then
            set_extmark(bufnr, ns, 0, 0, { virt_lines = virt_lines, virt_lines_above = true })
            if s then s.has_top_virt = true end
          else
            local anchor = math.min(hunk.new_start - 1, last_row)
            set_extmark(bufnr, ns, anchor, 0, { virt_lines = virt_lines, virt_lines_above = false })
            if s and anchor == last_row then s.has_bot_virt = true end
          end
        else
          -- Changed: whole old block above, whole new block below. Word-level
          -- highlights still come from pairing old[i] with new[i].
          local paired = math.min(hunk.old_count, hunk.new_count)
          local virt_lines = {}
          local new_highlights = {}

          for i = 1, paired do
            local old_line = hunk.old_lines[i] or ""
            local new_line = hunk.new_lines[i] or ""
            local old_segs, new_segs = diff._word_diff(old_line, new_line)
            virt_lines[#virt_lines + 1] = render._build_old_line_chunks(old_line, old_segs)
            new_highlights[i] = render._build_new_line_highlights(new_segs)
          end
          for i = paired + 1, hunk.old_count do
            virt_lines[#virt_lines + 1] = { { hunk.old_lines[i] or "", "InlineDiffDelete" } }
          end

          local first_new_idx = hunk.new_start - 1
          set_extmark(bufnr, ns, first_new_idx, 0, { virt_lines = virt_lines, virt_lines_above = true })
          if s and first_new_idx == 0 then s.has_top_virt = true end

          for i = 1, hunk.new_count do
            local new_line = hunk.new_lines[i] or ""
            local new_line_idx = hunk.new_start - 1 + (i - 1)
            set_extmark(bufnr, ns, new_line_idx, 0, {
              end_col = #new_line,
              hl_group = "InlineDiffAdd",
              hl_eol = true,
              priority = 200,
            })
            for _, hl in ipairs(new_highlights[i] or {}) do
              set_extmark(bufnr, ns, new_line_idx, hl.col, {
                end_col = hl.end_col,
                hl_group = hl.hl_group,
                priority = 300,
              })
            end
          end
        end
      end
    end

    local group = vim.api.nvim_create_augroup("InlineDiffGlobal", { clear = true })
    local global_on = false
    local global_ref = "HEAD"

    -- Only real, named file buffers — skip help/terminal/nofile/quickfix/etc.
    local function eligible(bufnr)
      return vim.api.nvim_buf_is_loaded(bufnr)
        and vim.bo[bufnr].buftype == ""
        and vim.api.nvim_buf_get_name(bufnr) ~= ""
    end

    local function enable_global(ref)
      global_on = true
      global_ref = ref or "HEAD"
      vim.api.nvim_clear_autocmds({ group = group })
      -- Auto-enable on every file buffer entered from now on.
      vim.api.nvim_create_autocmd("BufWinEnter", {
        group = group,
        callback = function(ev)
          if eligible(ev.buf) then
            inline.enable(ev.buf, global_ref)
          end
        end,
      })
      -- Catch buffers already open.
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if eligible(bufnr) then
          inline.enable(bufnr, global_ref)
        end
      end
    end

    local function disable_global()
      global_on = false
      vim.api.nvim_clear_autocmds({ group = group })
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
          inline.disable(bufnr)
        end
      end
    end

    local function toggle_global(ref)
      if global_on and not ref then
        disable_global()
      else
        enable_global(ref)
      end
    end

    vim.api.nvim_create_user_command("InlineDiffGlobal", function(a)
      toggle_global(a.args ~= "" and a.args or nil)
    end, { nargs = "?" })
  end,
}
