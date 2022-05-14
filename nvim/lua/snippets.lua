local ls = require("luasnip")
-- some shorthands...
local snip = ls.snippet
local node = ls.snippet_node
local text = ls.text_node
local insert = ls.insert_node
local func = ls.function_node
local choice = ls.choice_node
local dynamicn = ls.dynamic_node

require("luasnip.loaders.from_vscode").lazy_load()

local date = function() return {os.date('%d.%m.%Y')} end

ls.add_snippets(nil, {
  all = {
    snip({
      trig = "date",
      namr = "Date",
      dscr = "Date in the form of DD-MM-YYYY"
    }, {
      func(date, {})
    })
  },
  markdown = {
    snip({
      trig = "rwr",
      name = "Review",
      descr = "Populates a markdown file with a review template"
    }, {
      text({"# "}), insert(1, "reviewee"), text({"","",
      "---", "",
      "## Reviewer", "",
      "- "}), insert(2, "reviewer"), text({" <"}), insert(3, "email"), text({">", 
      "- Date: "}), func(date, {}), text({"",
      "- Revision: "}), insert(4, "revision"), text({"", "",
      "---", "", "",
			"## Creativity and inovation", "",
			"## Adaptability", "",
			"## Communication", "",
			"## Accountability", "", 
			"## Attendance and punctuality", "",
			"## Productivity and quality of work", "", 
			"## Achievement", "", 
			"## Cooperation", "",
			"## Improvement", "",
			"## Interpersonal skills", "",
			"## Problem solving"})
    })
  }
})


local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }
keymap("i", "<c-j>", "<cmd>lua require'luasnip'.jump(1)<CR>", opts)
keymap("s", "<c-j>", "<cmd>lua require'luasnip'.jump(1)<CR>", opts)
keymap("i", "<c-k>", "<cmd>lua require'luasnip'.jump(-1)<CR>", opts)
keymap("s", "<c-k>", "<cmd>lua require'luasnip'.jump(-1)<CR>", opts)
