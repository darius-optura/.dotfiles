function hw --description 'herdr worktree: create off origin/main, bootstrap, lay out nvim+claude+codex'
    # Usage: hw <branch>
    # Creates <repo>/.claude/worktrees/<branch>, runs the repo's .herdr/setup.sh
    # if present, then builds a 3-pane workspace via the herdr socket API:
    # nvim (root, left) | claude (top-right) | codex (bottom-right).
    #
    # NOTE: run this from inside a herdr session (a herdr server must be running).
    # The .result JSON field names below match herdr 0.8.2's API schema; if a
    # future version changes them, adjust the jq paths.
    if test (count $argv) -ne 1
        echo "usage: hw <branch>" >&2
        return 1
    end
    set -l branch $argv[1]

    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if test -z "$common"
        echo "hw: not inside a git repository" >&2
        return 1
    end
    set -l main (path dirname $common)
    set -l dir "$main/.claude/worktrees/$branch"
    if test -e $dir
        echo "hw: $dir already exists" >&2
        return 1
    end

    git -C $main fetch origin main --quiet; or return 1

    # 1. Create and open the worktree workspace. Capture the root pane id.
    set -l created (herdr worktree create --path $dir --branch $branch --base origin/main --no-focus)
    if test $status -ne 0
        echo "hw: herdr worktree create failed" >&2
        return 1
    end
    set -l root (echo $created | jq -r '.result.root_pane.pane_id')
    if test -z "$root" -o "$root" = null
        echo "hw: could not read root pane id from herdr response" >&2
        echo $created >&2
        return 1
    end

    # 2. Bootstrap (repo-owned, optional). Runs synchronously before agents start.
    if test -x "$main/.herdr/setup.sh"
        "$main/.herdr/setup.sh" $dir $branch; or return 1
    end

    # 3. Layout: nvim (root) + claude (top-right) + codex (bottom-right).
    _hw_layout $root $dir

    echo "hw: $branch -> $dir"
end
