function hw-open --description 'Open an existing .claude/worktrees/<branch> with nvim+claude+shell layout'
    # Usage: hw-open <branch>
    # Opens an existing worktree as a herdr workspace and lays out the same
    # 3 panes as `hw`. No bootstrap — the worktree is assumed already set up.
    if test (count $argv) -ne 1
        echo "usage: hw-open <branch>" >&2
        return 1
    end
    set -l branch $argv[1]

    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if test -z "$common"
        echo "hw-open: not inside a git repository" >&2
        return 1
    end
    set -l main (path dirname $common)
    set -l dir "$main/.claude/worktrees/$branch"
    if not test -d $dir
        echo "hw-open: no worktree at $dir" >&2
        return 1
    end

    set -l opened (herdr worktree open --path $dir --no-focus)
    if test $status -ne 0
        echo "hw-open: herdr worktree open failed" >&2
        return 1
    end
    set -l root (echo $opened | jq -r '.result.root_pane.pane_id')
    if test -z "$root" -o "$root" = null
        echo "hw-open: could not read root pane id from herdr response" >&2
        echo $opened >&2
        return 1
    end

    _hw_layout $root $dir
    echo "hw-open: opened $dir"
end
