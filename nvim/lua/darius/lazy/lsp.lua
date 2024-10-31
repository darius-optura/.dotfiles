return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		{ "towolf/vim-helm", ft = "helm" },
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/nvim-cmp",
		'onsails/lspkind.nvim',
		-- {
		-- 	"zbirenbaum/copilot-cmp",
		-- 	config = function()
		-- 		require("copilot_cmp").setup()
		-- 	end
		-- },

		{
			"L3MON4D3/LuaSnip",
			dependencies = {
				"rafamadriz/friendly-snippets",
			}
		},

		"saadparwaiz1/cmp_luasnip",
		"j-hui/fidget.nvim",
	},

	config = function()
		local cmp = require('cmp')
		local cmp_lsp = require("cmp_nvim_lsp")
		local capabilities = vim.tbl_deep_extend(
			"force",
			{},
			vim.lsp.protocol.make_client_capabilities(),
			cmp_lsp.default_capabilities())

		require("fidget").setup({
			notification = {
				window = {
					winblend = 0
				}
			}
		})
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = {
				"lua_ls",
				"tsserver",
				"dockerls",
				"gopls",
				"helm_ls",
				"yamlls"
			},

			handlers = {
				function(server_name) -- default handler (optional)
					require("lspconfig")[server_name].setup {
						capabilities = capabilities
					}
				end,

				["lua_ls"] = function()
					local lspconfig = require("lspconfig")
					lspconfig.lua_ls.setup {
						capabilities = capabilities,
						settings = {
							Lua = {
								diagnostics = {
									globals = { "vim", "it", "describe", "before_each", "after_each" },
								}
							}
						}
					}
				end,
				["helm_ls"] = function()
					local lspconfig = require("lspconfig")
					lspconfig.helm_ls.setup {
						capabilities = capabilities,
						settings = {
							['helm-ls'] = {
								yamlls = {
									path = "yaml-language-server"
								}
							}
						}
					}
				end,
				["yamlls"] = function()
					local lspconfig = require("lspconfig")
					lspconfig.yamlls.setup {
						capabilities = capabilities,
						opts = {
							filetypes_exclude = { "helm" }
						},
					}
				end
			}
		})

		local luasnip = require('luasnip')
		luasnip.config.setup {}

		local source_mapping = {
			buffer = "[Buffer]",
			nvim_lsp = "[LSP]",
			nvim_lua = "[Lua]",
			-- copilot = "[Copilot]",
			luasnip = "[Snip]",
			path = "[Path]",
			supermaven = "[Supermaven]",
		}
		local lspkind = require 'lspkind'

		lspkind.init({
			symbol_map = {
				Copilot = "",
				Supermaven = "",
			},
		})

		cmp.setup({
			snippet = {
				expand = function(args)
					require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
				end,
			},
			completion = {
				completeopt = 'menu,menuone,noinsert',
			},
			formatting = {
				format = function(entry, vim_item)
					vim_item.kind = lspkind.presets.default[vim_item.kind]
					local menu = source_mapping[entry.source.name]
					vim_item.menu = menu
					return vim_item
				end,
			},
			mapping = cmp.mapping.preset.insert({
				['<C-n>'] = cmp.mapping.scroll_docs(-4),
				['<C-p>'] = cmp.mapping.scroll_docs(4),
				['<C-Space>'] = cmp.mapping.complete {},
				['<C-y>'] = cmp.mapping.confirm {
					select = true,
				},
				['<C-k>'] = cmp.mapping(function()
					if luasnip.expand_or_jumpable() then
						luasnip.expand_or_jump()
					end
				end, { 'i', 's' }),
				['<C-j>'] = cmp.mapping(function()
					if luasnip.jumpable(-1) then
						luasnip.jump(-1)
					end
				end, { 'i', 's' }),
			}),
			sources = cmp.config.sources({
				{ name = 'supermaven', group_index = 2 },
				{ name = 'nvim_lsp',   group_index = 2 },
				{ name = 'buffer',     group_index = 2 },
				{ name = 'path',       group_index = 2 },
				{ name = 'luasnip',    group_index = 2 },
			})
		})

		vim.diagnostic.config({
			-- update_in_insert = true,
			float = {
				focusable = false,
				style = "minimal",
				border = "rounded",
				source = "always",
				header = "",
				prefix = "",
			},
		})
	end
}
