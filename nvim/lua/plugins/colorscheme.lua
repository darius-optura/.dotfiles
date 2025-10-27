return {
	-- {
	-- 	"rose-pine/neovim",
	-- 	name = "rose-pine",
	-- 	config = function()
	-- 		require("rose-pine").setup({
	-- 			disable_background = true,
	-- 			styles = {
	-- 				transparency = true,
	-- 			},
	-- 			variant = "moon",
	-- 			dark_variant = "moon",
	-- 		})
	--
	-- 		-- vim.cmd("colorscheme rose-pine")
	-- 	end,
	-- },
	{
		"catppuccin/nvim",
		name = "catppuccin",
		-- priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha", -- latte, frappe, macchiato, mocha
				transparent_background = true, -- disables setting the background color.)
				integrations = {
					blink_cmp = true,
					gitsigns = true,
					treesitter = true,
					notify = true,
					fidget = true,
					flash = true,
					harpoon = true,
					mini = {
						enabled = true,
						indentscope_color = "",
					},
					indent_blankline = {
						enabled = true,
						scope_color = "", -- catppuccin color (eg. `lavender`) Default: text
						colored_indent_levels = false,
					},
					mason = true,
					noice = true,
					snacks = {
						enabled = false,
						indent_scope_color = "", -- catppuccin color (eg. `lavender`) Default: text
					},
					telescope = {
						enabled = true,
					},
					which_key = true,
					-- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
				},
			})
			vim.cmd("colorscheme catppuccin")
			vim.api.nvim_set_hl(0, "Normal", { guibg = NONE, ctermbg = NONE })
		end,
	},
	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000,
		config = function()
			require("gruvbox").setup({
				{
					-- terminal_colors = true, -- add neovim terminal colors
					transparent_mode = true,
				},
			})
			-- vim.cmd("colorscheme gruvbox")
			-- vim.api.nvim_set_hl(0, "Normal", {guibg = NONE, ctermbg = NONE})
		end,
	},
	-- {
	-- 	"scottmckendry/cyberdream.nvim",
	-- 	lazy = false,
	-- 	-- priority = 1000,
	-- 	config = function()
	-- 		require("cyberdream").setup({
	-- 			-- variant = "default", -- use "light" for the light variant. Also accepts "auto" to set dark or light colors based on the current value of `vim.o.background`
	-- 			-- Enable transparent background
	-- 			transparent = true,
	-- 		})
	-- 	end,
	-- },
}
