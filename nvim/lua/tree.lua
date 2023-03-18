require("nvim-tree").setup{}

vim.api.nvim_set_keymap('n', '<leader>n', '<cmd>NvimTreeToggle<CR>', { noremap = true })
