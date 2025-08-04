return {
	-- {
	-- 	"saghen/blink.compat",
	-- 	-- use v2.* for blink.cmp v1.*
	-- 	version = "2.*",
	-- 	-- lazy.nvim will automatically load the plugin when it's required by blink.cmp
	-- 	lazy = true,
	-- 	-- make sure to set opts so that lazy.nvim calls blink.compat's setup
	-- 	opts = {},
	-- },
	{

		"saghen/blink.cmp",

		version = "1.*",
		dependencies = {
			{ "Kaiser-Yang/blink-cmp-avante" },
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
				default = { "lsp", "path", "snippets", "buffer", "avante" },
				providers = {
					avante = {
						module = "blink-cmp-avante",
						name = "Avante",
						opts = {
							-- options for blink-cmp-avante
						},
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
					enabled = false,
				},
				menu = {
					draw = {
						columns = { { "kind_icon" }, { "label", gap = 1 } },
						components = {
							kind_icon = {
								ellipsis = false,
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
						},
					},
				},
			},
		},
	},
}
