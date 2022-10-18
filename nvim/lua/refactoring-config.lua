local refactoring = require('refactoring')

refactoring.setup({})

-- remap to open the Telescope refactoring menu in visual mode
vim.api.nvim_set_keymap(
	"v",
	"<leader>rr",
	"<Esc><cmd>lua require('telescope').extensions.refactoring.refactors()<CR>",
	{ noremap = true }
)

vim.api.nvim_set_keymap("n", "<leader>ut", "<cmd>:UndotreeToggle<CR>", { noremap = true })
