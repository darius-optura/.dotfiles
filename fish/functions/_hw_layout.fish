function _hw_layout --description 'Lay out nvim + claude + a shell in a herdr worktree workspace'
    # args: <root-pane-id> <worktree-dir>
    # Layout:  nvim (top-left) | claude (top-right)
    #          ------- shell (full-width bottom) -------
    set -l root $argv[1]
    set -l dir $argv[2]

    # Bottom: full-width shell pane (~1/4 height). No agent — plain shell for
    # git, tests, commands. Split root down first so it spans full width.
    # herdr --ratio is the EXISTING pane's kept fraction, so 0.75 leaves the
    # bottom at ~25%.
    herdr pane split --pane $root --direction down --ratio 0.75 --cwd $dir --no-focus >/dev/null

    # Top-right: claude (~40% of the top row). Root (left/nvim) keeps 60%.
    set -l right (herdr pane split --pane $root --direction right --ratio 0.6 --cwd $dir --no-focus | jq -r '.result.pane.pane_id')
    herdr agent start claude --kind claude --pane $right

    # nvim in root (top-left). Let the shell start first so the command lands.
    sleep 1
    herdr pane send-text --pane $root "nvim ."(printf '\n')
    herdr pane focus --pane $root
end
