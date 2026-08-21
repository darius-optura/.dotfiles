# herdr verify-gate findings (herdr 0.8.2, macos/aarch64)

Date: 2026-08-21. Binary: `~/.local/bin/herdr`, v0.8.2.

## Answers to the gate questions

1. **Config path/format** — `~/.config/herdr/config.toml` (TOML). Override with
   `HERDR_CONFIG_PATH`. Reload a running server with `herdr server reload-config`
   or the `reload_config` key. Print defaults with `herdr --default-config`.

2. **Per-repo worktree directory template?** — **No.** `[worktrees] directory`
   is a single global base only (default `~/.herdr/worktrees`). No `{{ repo_root }}`
   template. **But** `herdr worktree create` takes explicit flags:
   `--path <PATH> --branch <NAME> --base <REF> --cwd --workspace --label
   --focus/--no-focus`. So an in-repo path is reachable by passing
   `--path <repo>/.claude/worktrees/<branch>`.

3. **`worktree.created` / `worktree.removed` config hooks?** — **No. Not in
   core.** The whole `--default-config` has no lifecycle-hook mechanism. The only
   config extension point is `[[keys.command]]` (a command bound to a key, type
   `shell` / `pane` / `popup`). The "lifecycle hooks" seen online are third-party
   plugins (herdr-plus, workspace-manager), not core. **This invalidates the
   plan's central mechanism (config-wired hooks calling `.herdr/setup.sh`).**

4. **Does created block opened / ordering?** — Moot. No hooks, so bootstrap and
   layout must run inside a wrapper we control, in sequence. Ordering is trivial.

5. **Named branch vs detached HEAD?** — `herdr worktree create --branch <NAME>
   --base <REF>` cuts a named branch. So `setup.sh` needs no detached-HEAD parsing
   when we drive create ourselves.

6. **Declarative workspace layout in config?** — **No.** No pane/agent layout
   config. Panes and agents are built over the socket API: `herdr pane <...>`,
   `herdr tab <...>`, `herdr agent <...>`, `herdr workspace <...>`. `herdr --skill`
   prints the agent skill that documents pane/agent control.

7. **Attach / new-session CLI (for `ghostty-shell`)?** — `herdr --session <name>`
   launches or attaches a named persistent session. Also `herdr session attach
   <name>` / `list` / `stop` / `delete`. Bare `herdr` attaches the default session.

8. **Key names (real defaults):**
   - prefix `ctrl+b`; detach `prefix+q`; settings `prefix+s`;
     reload_config `prefix+shift+r`; resize_mode `prefix+r`.
   - splits: `split_vertical=prefix+v`, `split_horizontal=prefix+minus`.
   - tabs: `new_tab=prefix+c`, `next_tab=prefix+n`, `previous_tab=prefix+p`,
     `switch_tab=prefix+1..9`, `close_tab=prefix+shift+x`.
   - panes: `focus_pane_left/down/up/right=prefix+h/j/k/l`, `close_pane=prefix+x`,
     `zoom=prefix+z`, `toggle_sidebar=prefix+b`, `edit_scrollback=prefix+e`
     (there is **no** tmux-style copy-mode key).
   - worktree: `new_worktree=prefix+shift+g`; `open_worktree` and
     `remove_worktree` are **unset by default** — must set them.
   - workspace: `new_workspace=prefix+shift+n`, `workspace_picker=prefix+w`.

9. **Attach a session by name from CLI?** — **Yes** (`herdr --session <name>` /
   `herdr session attach <name>`). tmux-sessionizer rewrite onto herdr is viable.

10. **Hook `run` external command + CWD?** — N/A for lifecycle (no hooks).
    `[[keys.command]]` runs a command string (shell/pane/popup) bound to a key.

## Impact on the plan

- **Approach A (core-config hooks + declarative layout) is not possible on
  0.8.2.** Pivot to **approach B**: a wrapper owns create → bootstrap → layout,
  and remove → teardown. herdr still provides the multiplexer, sessions, worktree
  git plumbing (`worktree create/remove`), and pane/agent API for the layout.
- Worktrees can still live in-repo via `worktree create --path`.
- Keybind reconcile (unit 5) is unaffected in shape; only the letter values are
  now confirmed. Note `super+k`→`prefix+s` is **settings**, not session-list, and
  reload is `prefix+shift+r`, not `prefix+r`.
