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

    # A failed removal unregisters the worktree but leaves every file behind, so
    # a checkout on disk is not proof that git still knows about it. Such an
    # orphan has no branch and no DB left to tear down: delete the files only.
    set -l registered 0
    for line in (git -C $main worktree list --porcelain | string replace -rf '^worktree ' '')
        if test (path resolve $line) = (path resolve $target)
            set registered 1
            break
        end
    end
    if test $registered -eq 0
        echo "hw-rm: $target is an orphan checkout, deleting the files"
        _hw_stop_procs $target
        _hw_remove_checkout $main $target; or return 1
        _hw_prune_parents $main $target
        echo "hw-rm: removed $target"
        return 0
    end

    set -l branch (git -C $target rev-parse --abbrev-ref HEAD)

    # Resolve the open herdr workspace before the checkout goes away.
    # The worktree JSON exposes it as `open_workspace_id`.
    set -l ws (herdr worktree list | jq -r --arg p $target '.result.worktrees[]? | select(.path == $p) | .open_workspace_id // empty' | head -n1)

    # Leave the worktree before it is unlinked, so this shell is not one of the
    # processes found below.
    if string match -q "$target*" (pwd)
        cd $main
    end

    # 1. Stop everything still running in the checkout, so the DB drop and the
    # file delete are not racing a live dev server.
    _hw_stop_procs $target

    # 2. Repo-owned teardown (salvage docs, drop DB) before the checkout goes.
    # Fatal on purpose: it carries gitignored docs/ back into the main checkout,
    # and those are lost for good once the checkout is deleted.
    if test -x "$main/.herdr/teardown.sh"
        "$main/.herdr/teardown.sh" $target $branch; or return 1
    end

    # 3. Remove the checkout, then the branch and the empty parent dirs.
    set -l removed 0
    _hw_remove_checkout $main $target; or set removed 1
    if test $removed -eq 0
        test "$branch" != HEAD; and git -C $main branch -D $branch
        _hw_prune_parents $main $target
        echo "hw-rm: removed $target"
    else
        echo "hw-rm: $branch kept, the checkout is still on disk" >&2
    end

    # 4. Close the herdr workspace LAST. When hw-rm runs from a pane inside that
    # workspace this kills the shell, so nothing may follow it. It runs even
    # when the delete failed above, because an open workspace is what holds the
    # leftover files.
    if test -n "$ws" -a "$ws" != null
        herdr workspace close $ws
    end
    return $removed
end
