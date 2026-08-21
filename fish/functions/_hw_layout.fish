function _hw_layout --description 'Lay out nvim + claude + a shell in a herdr worktree workspace'
    # args: <root-pane-id> <worktree-dir>
    # Layout:  nvim (top-left) | claude (top-right)
    #          ------- shell (full-width bottom) -------
    set -l root $argv[1]
    set -l dir $argv[2]

    # Bottom: full-width shell pane (~1/4 height). No agent — plain shell for
    # git, tests, commands. Split the root down first so it spans full width.
    herdr pane split --pane $root --direction down --ratio 0.25 --cwd $dir --no-focus >/dev/null

    # Top-right: claude (~40% of the top row width).
    set -l right (herdr pane split --pane $root --direction right --ratio 0.4 --cwd $dir --no-focus | jq -r '.result.pane.pane_id')
    herdr agent start claude --kind claude --pane $right

    # Top-left (root): nvim. Keep focus here.
    herdr pane send-text --pane $root "nvim ."(printf '\r')
    herdr pane focus --pane $root
end
