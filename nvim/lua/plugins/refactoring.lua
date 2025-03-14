return {
    'ThePrimeagen/refactoring.nvim',
    dependencies = {
      { 'nvim-lua/plenary.nvim' },
      { 'nvim-treesitter/nvim-treesitter' }
    },
	config = function ()
		require('refactoring').setup({})
		vim.keymap.set("v", "<leader>rr", "<Esc>:lua require('telescope').extensions.refactoring.refactors()<CR>", { noremap = true })
	end
}
