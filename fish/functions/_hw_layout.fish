function _hw_layout --description 'Lay out nvim + claude + a shell in a herdr worktree workspace'
    # args: <root-pane-id> <worktree-dir> <branch>
    # Layout:  nvim (top-left) | claude (top-right)
    #          ------- shell (full-width bottom) -------
    set -l root $argv[1]
    set -l dir $argv[2]
    set -l branch $argv[3]

    # Bottom: full-width shell pane (~1/4 height). No agent — plain shell for
    # git, tests, commands. Split root down first so it spans full width.
    # herdr --ratio is the EXISTING pane's kept fraction, so 0.75 leaves the
    # bottom at ~25%.
    herdr pane split --pane $root --direction down --ratio 0.75 --cwd $dir --no-focus >/dev/null

    # Top-right: claude (~40% of the top row). Root (left/nvim) keeps 60%.
    set -l right (herdr pane split --pane $root --direction right --ratio 0.6 --cwd $dir --no-focus | jq -r '.result.pane.pane_id')
    # Agent names are unique across the whole herdr server and must match
    # [a-z][a-z0-9_-]{0,31}, so derive one from the branch.
    set -l name claude-(string lower $branch | string replace -ra '[^a-z0-9_-]' - | string sub -l 25)
    herdr agent start $name --kind claude --pane $right

    # nvim in root (top-left). Let the shell start first so the command lands.
    sleep 1
    herdr pane run $root "nvim ."
    # herdr 0.8.2 has no focus-by-pane-id; the root pane is still the focused
    # pane of its workspace (all splits used --no-focus), so focus the workspace.
    herdr workspace focus (string split -f1 : $root)
end
