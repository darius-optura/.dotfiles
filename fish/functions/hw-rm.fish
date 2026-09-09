function hw-rm --description 'herdr worktree teardown: salvage docs, drop DB, remove worktree'
    # Usage: hw-rm [<branch>|<path>]   (defaults to the current worktree)
    # Runs the repo's .herdr/teardown.sh if present, then removes the worktree
    # via the herdr API (by workspace id) and deletes the branch.
    #
    # NOTE: run from inside a herdr session (a herdr server must be running).
    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if test -z "$common"
        echo "hw-rm: not inside a git repository" >&2
        return 1
    end
    set -l main (path dirname $common)

    set -l target
    if test (count $argv) -eq 0
        set target (git rev-parse --show-toplevel)
    else if test -d $argv[1]
        set target (path resolve $argv[1])
    else
        set target "$main/.claude/worktrees/$argv[1]"
    end

    if test (path resolve $target) = (path resolve $main)
        echo "hw-rm: refusing to remove the main checkout" >&2
        return 1
    end
    if not test -d $target
        echo "hw-rm: no worktree at $target" >&2
        return 1
    end

    set -l branch (git -C $target rev-parse --abbrev-ref HEAD)

    # 1. Repo-owned teardown (salvage docs, drop DB) before the checkout goes.
    if test -x "$main/.herdr/teardown.sh"
        "$main/.herdr/teardown.sh" $target $branch; or return 1
    end

    # Leave the worktree before it is unlinked.
    if string match -q "$target*" (pwd)
        cd $main
    end

    # Resolve the open herdr workspace before the checkout goes away.
    # The worktree JSON exposes it as `open_workspace_id`.
    set -l ws (herdr worktree list | jq -r --arg p $target '.result.worktrees[]? | select(.path == $p) | .open_workspace_id // empty' | head -n1)

    # 2. Remove the checkout and branch with plain git. Also drop the empty
    # parent dirs a slash in the branch name created (.claude/worktrees/<owner>/).
    # --force twice: the second one overrides a `git worktree lock` (supacode
    # locks every worktree it adopts).
    git -C $main worktree remove --force --force $target; or return 1
    test "$branch" != HEAD; and git -C $main branch -D $branch
    set -l parent (path dirname $target)
    while test "$parent" != "$main/.claude/worktrees"; and rmdir $parent 2>/dev/null
        set parent (path dirname $parent)
    end
    echo "hw-rm: removed $target"

    # 3. Close the herdr workspace LAST. When hw-rm runs from a pane inside that
    # workspace this kills the shell, so nothing may follow it.
    if test -n "$ws" -a "$ws" != null
        herdr workspace close $ws
    end
end
