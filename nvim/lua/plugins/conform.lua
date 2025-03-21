return {
	"stevearc/conform.nvim",
	opts = {
		format_on_save = {
			-- These options will be passed to conform.format()
			timeout_ms = 500,
			lsp_format = "fallback",
		},
		formatters_by_ft = {
			lua = { "stylua" },
			javascript = { "biome", "prettierd", "prettier", stop_after_first = true },
			typescript = { "biome", "prettierd", "prettier", stop_after_first = true },
			golang = { "gofumpt", "goimports" },
		},
	},
}
