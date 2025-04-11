return {

	"saghen/blink.cmp",

	version = "1.*",
	dependencies = {
		{ "Kaiser-Yang/blink-cmp-avante" },
		{ "mechasnovski/mini.icons", opts = {} },
		{ "xzbdmw/colorful-menu.nvim", opts = {} },
	},
	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		keymap = { preset = "default" },
		cmdline = { completion = { ghost_text = { enabled = true } } },

		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "mono",
		},

		sources = {
			default = { "lsp", "path", "buffer", "avante" },
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
}
