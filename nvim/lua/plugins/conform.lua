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
			javascript = { "prettierd", "eslint_d", stop_after_first = true },
			typescript = { "prettierd", "eslint_d", stop_after_first = true },
			golang = { "gofumpt", "goimports" },
			css = { "prettierd" },
			scss = { "prettierd" },
			less = { "prettierd" },
		},
	},
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format()
			end,
			{ desc = "Format current buffer" },
		},
	},
}
