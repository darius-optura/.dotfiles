return {
  "ThePrimeagen/99",
  config = function()
    local _99 = require("99")

    local cwd = vim.uv.cwd()
    local basename = vim.fs.basename(cwd)

    _99.setup({
      model = "anthropic/claude-opus-4-6",
      provider = _99.Providers.ClaudeCodeProvider,
      logger = {
        level = _99.DEBUG,
        path = "/tmp/" .. basename .. ".99.debug",
        print_on_error = true,
      },
      completion = {
        source = "blink",
      },
      md_files = {
        "AGENTS.md",
        "AGENT.md",
        "CLAUDE.md",
      },
    })

    -- AI edit visual selection
    vim.keymap.set("v", "<leader>9v", function()
      _99.visual()
    end, { desc = "99: Visual edit" })

    -- AI search
    vim.keymap.set("n", "<leader>9/", function()
      _99.search()
    end, { desc = "99: Search" })

    -- Stop all requests
    vim.keymap.set("n", "<leader>9s", function()
      _99.stop_all_requests()
    end, { desc = "99: Stop requests" })
  end,
}
