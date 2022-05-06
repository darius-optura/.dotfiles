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
    },
    ["ui-select"] = {
      require("telescope.themes").get_dropdown {
        -- even more opts
      }
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
          ["<C-z>"] = require'telescope'.extensions.send_to_harpoon.actions.send_selected_to_harpoon
        },
        n = {
          ["<C-z>"] = require'telescope'.extensions.send_to_harpoon.actions.send_selected_to_harpoon
        }
      }
    }
  }
}

telescope.load_extension("git_worktree")
telescope.load_extension("fzf")
telescope.load_extension("harpoon")
telescope.load_extension("send_to_harpoon")
telescope.load_extension("ui-select")
telescope.load_extension("refactoring")

vim.api.nvim_set_keymap('n', '<leader>ff', "<cmd>lua require('telescope.builtin').find_files()<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>fg', "<cmd>lua require('telescope.builtin').live_grep()<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>fb', "<cmd>lua require('telescope.builtin').buffers()<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>cb', "<cmd>lua require('telescope').extensions.git_worktree.git_worktrees()<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>gc', "<cmd>lua require('telescope.builtin').git_status()<CR>", {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>s', '<cmd>lua require("telescope.builtin").current_buffer_fuzzy_find()<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>r', '<cmd>lua require("telescope.builtin").registers()<CR>', {noremap = true})
