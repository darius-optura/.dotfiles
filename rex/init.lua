-- Rex tryout: the herdr keys from ghostty/config, ported to Rex.
-- Cmd+F sessionizer, Cmd+K session switcher, Cmd+G Glance PR.
-- Reload with `rex config reload` after a change.

local terminal = "com.superlogical.terminal"
local shell = "com.superlogical.terminal.shell"

-- The working directory a terminal last reported, as a plain path. Rex returns
-- it as a file:// URL with the host name in front.
local function block_dir(block_id)
  local r = rex.block.call(terminal, "pwd", { block_id = block_id })
  if not r or not r.pwd then
    return nil
  end
  local path = r.pwd:gsub("^file://[^/]*", "")
  return (path:gsub("%%(%x%x)", function(h)
    return string.char(tonumber(h, 16))
  end))
end

-- Type text into the focused terminal, as the ghostty `text:` binds do.
local function typer(data)
  return function(ctx)
    rex.block.call(terminal, "write", { block_id = ctx.block_id, data = data })
    return true
  end
end

-- Panes and tabs, on the same keys ghostty sent to herdr.
rex.bind("cmd+n", "pane.split.right")
rex.bind("cmd+shift+n", "pane.split.down")
rex.bind("cmd+w", "pane.close")
rex.bind("cmd+z", "pane.zoom")
rex.bind("cmd+up", "pane.focus.up")
rex.bind("cmd+down", "pane.focus.down")
rex.bind("cmd+left", "pane.focus.left")
rex.bind("cmd+right", "pane.focus.right")
rex.bind("cmd+t", "client.tab.new")
rex.bind("cmd+shift+t", "pane.move_to_new_tab")
rex.bind("cmd+shift+[", "client.tab.previous")
rex.bind("cmd+shift+]", "client.tab.next")
rex.bind("cmd+,", "client.tab.rename")
for i = 1, 9 do
  rex.bind("cmd+" .. i, "client.tab.goto", { index = i })
end

-- Cmd+S saves in nvim; Cmd+R starts the intent dev server in the worktree.
rex.bind("cmd+s", typer("\27:w\n"))
rex.bind("cmd+r", typer("INTENT_WORKTREE_SKIP_SEED=true npm run dev:isolated\n"))

-- Cmd+F: fzf a project dir in a floating pane, then open or switch to its
-- session (bin/rex-sessionizer). The pane closes when the picker exits.
rex.bind("cmd+f", function(ctx)
  rex.session.new_layer({
    session_id = ctx.session_id,
    bounds = { 0.1, 0.1, 0.8, 0.8 },
    focus = true,
    layout = rex.layout.block({ flavor = shell, options = { command = { "rex-sessionizer" } } }),
  })
  return true
end)

-- Cmd+K: Rex's own session switcher, in place of herdr-bar.
rex.bind("cmd+k", "session.switch")

-- Cmd+G: Glance PR for the focused terminal's checkout, split to the right.
rex.bind("cmd+g", function(ctx)
  local dir = block_dir(ctx.block_id)
  if not dir then
    return false
  end
  rex.session.new_split({
    session_id = ctx.session_id,
    anchor_id = ctx.block_id,
    direction = "horizontal",
    side = "after",
    ratio = 0.72,
    layout = rex.layout.block({
      flavor = shell,
      options = { cwd = dir, command = { "herdr-pr-glance", "view", "--cwd", dir } },
    }),
  })
  return true
end)
