return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		dependencies = {
			{ "mechasnovski/mini.icons", opts = {} },
			{ "xzbdmw/colorful-menu.nvim", opts = {} },
			{
				"L3MON4D3/LuaSnip",
				version = "v2.*",
				dependencies = { "rafamadriz/friendly-snippets" },
				build = "make install_jsregexp",
				config = function()
					require("luasnip.loaders.from_vscode").lazy_load()
				end,
			},

			{
				"saghen/blink.compat",
				-- use v2.* for blink.cmp v1.*
				version = "2.*",
				-- lazy.nvim will automatically load the plugin when it's required by blink.cmp
				lazy = true,
				-- make sure to set opts so that lazy.nvim calls blink.compat's setup
				opts = {},
				dependencies = {
					{
						"supermaven-inc/supermaven-nvim",
						opts = {
							disable_inline_completion = true,
							disable_keymaps = true,
						},
					},
				},
			},
			-- {
			-- 	"supermaven-inc/supermaven-nvim",
			-- 	dependencies = {
			-- 		"huijiro/blink-cmp-supermaven",
			-- 	},
			-- 	opts = {
			-- 		disable_inline_completion = true, -- disables inline completion for use with cmp
			-- 		disable_keymaps = true, -- disables built in keymaps for more manual control
			-- 	},
			-- },
		},
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = { preset = "default" },
			cmdline = { completion = { ghost_text = { enabled = true } } },

			snippets = { preset = "luasnip" },
			appearance = {
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "mono",
			},

			sources = {
				default = { "lsp", "path", "snippets", "buffer", "supermaven" },
				providers = {
					supermaven = {
						name = "supermaven",
						module = "blink.compat.source",
						score_offset = 3,
					},
				},
			},
			signature = {
				enabled = true,
			},
			completion = {
				documentation = {
					auto_show = true,
				},
				ghost_text = {
					enabled = true,
				},
				menu = {
					draw = {
						columns = { { "kind_icon" }, { "label", gap = 1 }, { "source_name" } },
						components = {
							kind_icon = {
								ellipsis = true,
								text = function(ctx)
									local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
									return kind_icon .. ctx.icon_gap
								end,
								-- Optionally, you may also use the highlights from mini.icons
								highlight = function(ctx)
									local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
									return hl
								end,
							},
							label = {
								text = function(ctx)
									return require("colorful-menu").blink_components_text(ctx)
								end,
								highlight = function(ctx)
									return require("colorful-menu").blink_components_highlight(ctx)
								end,
							},
							source_name = {
								text = function(ctx)
									local icons = {
										LSP = "󰒋",
										Buffer = "󰈙",
										Path = "󰉋",
										Snippets = "󰩫",
										supermaven = "󰚩",
									}
									-- -- Debug: print the actual source name
									-- vim.schedule(function()
									-- 	print("Source name: '" .. tostring(ctx.source_name) .. "'")
									-- end)
									-- local icon = icons[ctx.source_name]
									-- if icon then
									-- 	return icon
									-- else
									-- 	-- Show both fallback icon and the actual source name for debugging
									-- 	return "󰘦[" .. tostring(ctx.source_name) .. "]"
									-- end
									return icons[ctx.source_name] or "󰘦"
								end,
								highlight = "BlinkCmpSource",
							},
						},
					},
				},
			},
		},
	},
}
