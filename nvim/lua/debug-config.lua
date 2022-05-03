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

-- vim.keymap.set("n", "<leader>dc", ":lua require'dap'.continue()<CR>")
-- vim.keymap.set("n", "<leader>dj",":lua require'dap'.step_over()<CR>")
-- vim.keymap.set("n", "<leader>dl", ":lua require'dap'.step_into()<CR>")
-- vim.keymap.set("n", "<leader>dh", ":lua require'dap'.step_out()<CR>")
-- vim.keymap.set("n", "<leader>b", ":lua require'dap'.toggle_breakpoint()<CR>")
-- vim.keymap.set("n", "<leader>B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>")
-- vim.keymap.set("n", "<leader>lp", ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>")
-- vim.keymap.set("n", "<leader>dr", ":lua require'dap'.repl.open()<CR>")
-- vim.keymap.set("n", "<leader>dt", ":lua require'dap-go'.debug_test()<CR>")
-- vim.keymap.set("n", "<leader>dx", ":lua requure'dap'terminate()<CR>")

-- require("nvim-dap-virtual-text").setup()
-- require('dap-go').setup()
-- require("dapui").setup()

-- local dap, dapui = require("dap"), require("dapui")
-- dap.listeners.after.event_initialized["dapui_config"] = function()
--   dapui.open()
-- end
-- dap.listeners.before.event_terminated["dapui_config"] = function()
--   dapui.close()
-- end
-- dap.listeners.before.event_exited["dapui_config"] = function()
--   dapui.close()
-- end
