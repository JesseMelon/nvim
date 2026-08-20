return {
  "cvlmtg/inline-diff.nvim",
  config = function()
    local inline = require("inline-diff")
    inline.setup()

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
