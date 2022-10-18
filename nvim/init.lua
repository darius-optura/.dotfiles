require('basics')
require('colors')
require('telescope-config')
require('lsp')
require('snippets')
require('harpoon-config')
require('debug-config')
require('git')
require('refactoring-config')
require('hop-config')
require('lualine').setup()

require 'nvim-treesitter.configs'.setup {
  ensure_installed = "all",
  context_commentstring = {
    enable = true
  },
  highlight = {
    enable = true
  },
  indent = {
    enable = true
  }
}

vim.notify = require("notify")

return require('packer').startup(function()
  -- PLUGIN MANAGER
  use 'wbthomason/packer.nvim'

  -- THEME

  -- use 'cupsadarius/vim-horizon'
  -- use 'morhetz/gruvbox'
  -- use 'drewtempelmeyer/palenight.vim'
  use({
    "catppuccin/nvim",
    as = "catppuccin"
  })
  -- use 'folke/tokyonight.nvim'
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    config = function()
      require "lualine".setup { theme = 'catppuccin' }
    end
  }
  use "lukas-reineke/indent-blankline.nvim"


  -- TELESCOPE
  use {
    'nvim-telescope/telescope.nvim',
    requires = { { 'nvim-lua/plenary.nvim' } }
  }
  use {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = 'make'
  }
  use { 'nvim-telescope/telescope-ui-select.nvim' }
  use 'asbjornhaland/telescope-send-to-harpoon.nvim'
  use 'ThePrimeagen/git-worktree.nvim'
  use 'ThePrimeagen/harpoon'
  use 'rcarriga/nvim-notify'

  -- COMENTS

  use 'tpope/vim-commentary'
  use 'JoosepAlviste/nvim-ts-context-commentstring'

  -- GIT

  use 'kdheepak/lazygit.nvim'

  -- REFACTORING

  use {
    "ThePrimeagen/refactoring.nvim",
    requires = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" }
    }
  }
  use {
    "ur4ltz/surround.nvim",
    config = function()
      require "surround".setup { mappings_style = "surround" }
    end
  }
  use "mbbill/undotree"
  use {
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons', -- optional, for file icons
    },
  }

  -- TREESITTER

  use 'nvim-treesitter/nvim-treesitter'
  use 'nvim-treesitter/nvim-treesitter-textobjects'
  use 'nvim-treesitter/nvim-treesitter-context'

  -- DEBUGING

  use 'puremourning/vimspector'
  -- use 'mfussenegger/nvim-dap'
  -- use 'leoluz/nvim-dap-go'
  -- use 'rcarriga/nvim-dap-ui'
  -- use 'theHamsta/nvim-dap-virtual-text'
  -- use 'nvim-telescope/telescope-dap.nvim'
  -- use 'Pocco81/dap-buddy.nvim'

  -- LSP

  use 'williamboman/nvim-lsp-installer'
  use 'neovim/nvim-lspconfig'
  use 'onsails/lspkind.nvim'

  -- AUTOCOMPLETE
  use 'hrsh7th/nvim-cmp' -- Autocompletion plugin
  use { 'tzachar/cmp-tabnine', run = './install.sh', requires = 'hrsh7th/nvim-cmp' }
  use 'hrsh7th/cmp-nvim-lsp' -- LSP source for nvim-cmp
  use 'saadparwaiz1/cmp_luasnip' -- Snippets source for nvim-cmp
  use 'L3MON4D3/LuaSnip' -- Snippets plugin
  use "rafamadriz/friendly-snippets"
  -- use 'github/copilot.vim'
  -- use 'hrsh7th/cmp-copilot'
  -- Lua

  -- MARKDOWN

  use { "ellisonleao/glow.nvim", branch = 'main' }

  -- TODOS

  use {
    "folke/todo-comments.nvim",
    requires = "nvim-lua/plenary.nvim",
    config = function()
      require("todo-comments").setup {}
    end
  }

  -- MOTIONS
  use {
    'mg979/vim-visual-multi',
    branch = 'master'
  }

  use {
    'phaazon/hop.nvim',
    branch = 'v1', -- optional but strongly recommended
    config = function()
      -- you can configure Hop the way you like here; see :h hop-config
      require 'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
    end
  }

  -- TRACKING

  use 'wakatime/vim-wakatime'
end)
