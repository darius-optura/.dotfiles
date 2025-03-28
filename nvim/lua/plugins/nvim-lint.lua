return {
	"mfussenegger/nvim-lint",
	-- "JonnyLoughlin/nvim-lint",
	-- branch="golangcilint-fix",
	ft = { "go", "lua", "javascript", "typescript", "typescriptreact", "sh", "bash" },
	lazy = true,
	event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
	config = function()
		local lint = require("lint")
		lint.linters_by_ft = {
			go = { "golangcilint" },

			lua = { "luacheck" },

			css = { "stylelint" },

			bash = { "shellcheck" },
			javascript = { "eslint_d" },

			typescript = { "eslint_d" },
		}
		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}
