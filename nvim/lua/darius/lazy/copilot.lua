return {

    "supermaven-inc/supermaven-nvim",
    config = function()
        require("supermaven-nvim").setup({
            disable_inline_completion = true,   -- disables inline completion for use with cmp
            disable_keymaps = true              -- disables built in keymaps for more manual control
        })
    end,

    -- "zbirenbaum/copilot.lua",
    -- config = function()
    --   require("copilot").setup({
    --     suggestion = { enabled = false },
    --     panel = { enabled = false },
    --   })
    -- end
}
