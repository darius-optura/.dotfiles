function _hw_layout --description 'Lay out nvim + claude + a shell in a herdr worktree workspace'
    # args: <root-pane-id> <worktree-dir> <branch>
    # Layout:  nvim (top-left) | claude (top-right) | glance
    #          ------ shell (bottom) ------------------ |  (PR)
    set -l root $argv[1]
    set -l dir $argv[2]
    set -l branch $argv[3]

    # Right column, full height: Glance PR plugin (~44 columns). Opened first so
    # the later down-split of root spans only the left part. `plugin action
    # invoke` always targets the UI-focused pane, so open the plugin pane
    # directly, size it like the plugin does, and record it in the plugin's
    # state file so prefix+g focuses this pane instead of opening a second one.
    set -l glance (herdr plugin pane open --plugin glance.pr --entrypoint view --placement split --direction right --target-pane $root --no-focus | jq -r '.result.plugin_pane.pane.pane_id // empty')
    if test -n "$glance"
        set -l amount (herdr pane layout --pane $glance | jq -r --arg g $glance '.result.layout | (.panes[] | select(.pane_id == $g) | .rect.width) / .area.width - (44 / .area.width) | . * 100 | round / 100')
        test "$amount" != null; and herdr pane resize --pane $glance --direction right --amount $amount >/dev/null
        set -l state ~/.local/state/herdr/plugins/glance.pr/panes.json
        mkdir -p (path dirname $state); test -f $state; or echo '{}' >$state
        jq -c --arg t (string split -f1 : $root):t1 --arg p $glance '. + {($t): $p}' $state >$state.tmp; and mv $state.tmp $state
    end

    # Bottom: shell pane (~1/4 height) under nvim+claude. No agent — plain
    # shell for git, tests, commands. herdr --ratio is the EXISTING pane's
    # kept fraction, so 0.75 leaves the bottom at ~25%.
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
