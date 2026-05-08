return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		{
			"nvim-treesitter/nvim-treesitter-context",
			config = function()
				require("treesitter-context").setup({})
			end,
		},
	},
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup({})

		-- ensure parsers are installed
		local ensure_installed = {
			"vimdoc",
			"javascript",
			"typescript",
			"lua",
			"jsdoc",
			"bash",
			"css",
			"scss",
			"html",
			"go",
			"tsx",
			"vim",
			"markdown",
			"markdown_inline",
			"yaml",
			"svelte",
		}
		local installed = require("nvim-treesitter.config").get_installed()
		local to_install = vim.tbl_filter(function(lang)
			return not vim.list_contains(installed, lang)
		end, ensure_installed)
		if #to_install > 0 then
			require("nvim-treesitter.install").install(to_install)
		end

		-- treesitter-based highlighting and indentation
		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local ok, parser = pcall(vim.treesitter.get_parser, args.buf)
				if ok and parser then
					vim.treesitter.start(args.buf)
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})

		-- incremental selection via treesitter nodes
		local current_node = nil
		local node_stack = {}

		local function select_node(node)
			local sr, sc, er, ec = node:range()
			vim.fn.setpos("'<", { 0, sr + 1, sc + 1, 0 })
			vim.fn.setpos("'>", { 0, er + 1, ec, 0 })
			vim.cmd("normal! gv")
		end

		local function same_range(a, b)
			local ar1, ac1, ar2, ac2 = a:range()
			local br1, bc1, br2, bc2 = b:range()
			return ar1 == br1 and ac1 == bc1 and ar2 == br2 and ac2 == bc2
		end

		vim.keymap.set("n", "<Enter>", function()
			current_node = vim.treesitter.get_node()
			if not current_node then
				return
			end
			node_stack = { current_node }
			select_node(current_node)
		end, { desc = "Init treesitter selection" })

		vim.keymap.set("x", "<Enter>", function()
			if not current_node then
				return
			end
			local node = current_node:parent()
			while node and same_range(node, current_node) do
				node = node:parent()
			end
			if node then
				table.insert(node_stack, current_node)
				current_node = node
			end
			select_node(current_node)
		end, { desc = "Increment treesitter selection" })

		vim.keymap.set("x", "<Backspace>", function()
			if not current_node or #node_stack == 0 then
				return
			end
			current_node = table.remove(node_stack)
			select_node(current_node)
		end, { desc = "Decrement treesitter selection" })
	end,
}
