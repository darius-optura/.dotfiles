require('basics')
require('colors')
require('telescope-config')
require('lsp')
require('harpoon-config')
require('debug-config')
require('git')
require('lualine').setup()

require'nvim-treesitter.configs'.setup {
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

return require('packer').startup(function()
  use 'wbthomason/packer.nvim'
  use 'folke/tokyonight.nvim'
  use 'nvim-treesitter/nvim-treesitter' 
  use 'tpope/vim-commentary'
  use 'JoosepAlviste/nvim-ts-context-commentstring'
  use 'puremourning/vimspector'
  use 'ThePrimeagen/git-worktree.nvim'
  use 'ThePrimeagen/harpoon'
  use 'kdheepak/lazygit.nvim'
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/nvim-cmp' -- Autocompletion plugin
  use {'tzachar/cmp-tabnine', run='./install.sh', requires = 'hrsh7th/nvim-cmp'}
  use 'hrsh7th/cmp-nvim-lsp' -- LSP source for nvim-cmp
  use 'saadparwaiz1/cmp_luasnip' -- Snippets source for nvim-cmp
  use 'L3MON4D3/LuaSnip' -- Snippets plugin  
  use 'onsails/lspkind.nvim'
  use 'github/copilot.vim'
  use 'hrsh7th/cmp-copilot'
  -- use 'cupsadarius/vim-horizon'
  -- use 'morhetz/gruvbox'
  -- use 'drewtempelmeyer/palenight.vim'
  use({
	  "catppuccin/nvim",
	  as = "catppuccin"
  })
  use {
    'nvim-lualine/lualine.nvim',
    requires = {'kyazdani42/nvim-web-devicons', opt = true}
  }
  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  use {
    "ur4ltz/surround.nvim",
    config = function()
      require"surround".setup {mappings_style = "surround"}
    end
  }
  use {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = 'make'
  }
  use {"ellisonleao/glow.nvim", branch = 'main'}
end)
