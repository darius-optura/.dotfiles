function _hw_layout --description 'Lay out nvim + claude + codex in a herdr worktree workspace'
    # args: <root-pane-id> <worktree-dir>
    # Splits the root pane right for claude, then splits that down for codex,
    # runs nvim in the root pane, and keeps focus there.
    set -l root $argv[1]
    set -l dir $argv[2]

    set -l right (herdr pane split --pane $root --direction right --cwd $dir --no-focus | jq -r '.result.pane.pane_id')
    herdr agent start claude --kind claude --pane $right

    set -l bottom (herdr pane split --pane $right --direction down --cwd $dir --no-focus | jq -r '.result.pane.pane_id')
    herdr agent start codex --kind codex --pane $bottom

    herdr pane send-text --pane $root "nvim ."(printf '\r')
    herdr pane focus --pane $root
end
