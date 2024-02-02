return {
	{
		"folke/trouble.nvim",
		config = function()
			require("trouble").setup({
				icons = false,
			})

			vim.keymap.set("n", "<leader>tt", function()
				require("trouble").toggle()
			end)

			vim.keymap.set("n", "[t", function()
				require("trouble").next({ skip_groups = true, jump = true });
			end)

			vim.keymap.set("n", "]t", function()
				require("trouble").previous({ skip_groups = true, jump = true });
			end)

			vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
		end
	},
}
