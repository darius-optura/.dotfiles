return {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
        "nvim-treesitter/playground",
        "nvim-treesitter/nvim-treesitter-refactor",
        'nvim-treesitter/nvim-treesitter-context'
    },
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter.configs").setup({
            -- A list of parser names, or "all"
            ensure_installed = {
                "vimdoc", "javascript", "typescript", "lua",
                "jsdoc", "bash", 'css', 'scss', 'html', 'go',
                'tsx', 'vim', 'markdown', 'yaml'
            },

            -- Install parsers synchronously (only applied to `ensure_installed`)
            sync_install = false,

            -- Automatically install missing parsers when entering buffer
            -- Recommendation: set to false if you don"t have `tree-sitter` CLI installed locally
            auto_install = true,

            indent = {
                enable = true
            },

            highlight = {
                -- `false` will disable the whole extension
                enable = true,
            },
						incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<Enter>", -- set to `false` to disable one of the mappings
                    node_incremental = "<Enter>",
                    scope_incremental = false,
                    node_decremental = "<Backspace>",
                },
            },
        })
    end
}
