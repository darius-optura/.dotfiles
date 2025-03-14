return {
    -- {
    --     -- Theme inspired by Atom
    --     "catppuccin/nvim",
    --     name = 'catppuccin',
    -- },
    {
        "rose-pine/neovim",
        name = "rose-pine",
        config = function()
            require('rose-pine').setup({
                disable_background = true,
                styles = {
                    transparency = true
                },
                variant = "moon",
                dark_variant = "moon"
            })

            vim.cmd("colorscheme rose-pine")
        end
    },
    -- {
    --     "akinsho/horizon.nvim",
    --     name = "horizon",
    --     opts = {
    --         overrides = {
    --             colors = {
    --                 Normal = { bg = 'NONE' },
    --                 NormalFloat = { bg = 'NONE' }
    --             }
    --         }
    --     },
    --     config = function()
    --         require('horizon').setup({})
    --         vim.cmd("colorscheme horizon")
    --     end
    -- }

}
