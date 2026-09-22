return {
	"nvim-lualine/lualine.nvim",
	priority = 0,
	config = function()
		require("lualine").setup({
		  	options = {
		    		theme = 'auto'
			},
			sections = {
				lualine_b = {
					'branch',
					{
						'diff',
						source = function()
							local gs = vim.b.gitsigns_status_dict
							if gs then
								return {
									added = gs.added,
									modified = gs.changed,
									removed = gs.removed,
								}
							end
						end,
					},
					'diagnostics',
				},
			},
		})
	end
}
