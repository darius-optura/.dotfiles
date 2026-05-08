return {
	"ThePrimeagen/refactoring.nvim",
	dependencies = {
		{ "nvim-lua/plenary.nvim" },
		{ "nvim-treesitter/nvim-treesitter" },
		{ "lewis6991/async.nvim" },
	},
	config = function()
		require("refactoring").setup({})
		vim.keymap.set(
			"v",
			"<leader>rr",
			"<Esc>:lua require('telescope').extensions.refactoring.refactors()<CR>",
			{ noremap = true }
		)
	end,
}
