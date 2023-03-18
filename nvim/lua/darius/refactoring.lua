local refactoring = require('refactoring')

refactoring.setup({})

-- remap to open the Telescope refactoring menu in visual mode
vim.keymap.set("v", "<leader>rr", "<Esc>:lua require('telescope').extensions.refactoring.refactors()<CR>", { noremap = true })
