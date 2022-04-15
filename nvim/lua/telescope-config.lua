local telescope = require("telescope")

telescope.setup{
  defaults = {
    file_ignore_patterns = { "yarn.lock", "package-lock.json", "node_modules", ".git" }
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = false,
      override_file_sorter = true,
      case_mode = "smart_case"
    }
  },
  pickers = {
    buffers = {
      show_all_buffers = true,
      sort_lastused = true,
      -- theme = "dropdown",
      -- previewer = false,
      mappings = {
        i = {
          ["<M-d>"] = "delete_buffer",
        }
      }
    }
  }
}

telescope.load_extension("git_worktree")
telescope.load_extension("fzf")

vim.api.nvim_set_keymap('n', '<leader>ff', "<cmd>lua require('telescope.builtin').find_files()<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>fg', "<cmd>lua require('telescope.builtin').live_grep()<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>fb', "<cmd>lua require('telescope.builtin').buffers()<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>cb', "<cmd>lua require('telescope').extensions.git_worktree.git_worktrees()<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>gc', "<cmd>lua require('telescope.builtin').git_status()<CR>", {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>g', '<cmd>lua require("telescope.builtin").current_buffer_fuzzy_find()<CR>', {noremap = true})
