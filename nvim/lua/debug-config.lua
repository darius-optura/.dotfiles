-- For more adapters check https://github.com/puremourning/vimspector

vim.api.nvim_set_keymap('n', '<leader>dd', ':call vimspector#Launch()<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>dx', ':call vimspector#Stop()<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>dc', ':call vimspector#Continue()<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>dt', ':call vimspector#ToggleBreakpoint()<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>dw', ':VimspectorWatch', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>dr', ':VimspectorReset', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>de', ':VimspectorEval', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>dj', ':call vimspector#StepOver()<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>dl', ':call vimspector#StepInto()<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>dh', ':call vimspector#StepOut()<CR>', {noremap = true})
