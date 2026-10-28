function rw-rm --description 'Rex worktree teardown: salvage docs, drop DB, remove worktree, close session'
    # Usage: rw-rm [<branch>|<path>]   (defaults to the current worktree)
    # Rex port of hw-rm. Runs the repo's .herdr/teardown.sh if present, removes
    # the worktree and its branch, then kills the branch's Rex session.
    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if test -z "$common"
        echo "rw-rm: not inside a git repository" >&2
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
        echo "rw-rm: refusing to remove the main checkout" >&2
        return 1
    end
    if not test -d $target
        echo "rw-rm: no worktree at $target" >&2
        return 1
    end

    # A failed removal unregisters the worktree but leaves every file behind.
    # Such an orphan has no branch and no DB left to tear down: delete the files.
    set -l registered 0
    for line in (git -C $main worktree list --porcelain | string replace -rf '^worktree ' '')
        if test (path resolve $line) = (path resolve $target)
            set registered 1
            break
        end
    end
    if test $registered -eq 0
        echo "rw-rm: $target is an orphan checkout, deleting the files"
        _hw_stop_procs $target
        _hw_remove_checkout $main $target; or return 1
        _hw_prune_parents $main $target
        echo "rw-rm: removed $target"
        return 0
    end

    set -l branch (git -C $target rev-parse --abbrev-ref HEAD)

    # Resolve the Rex session before the checkout goes away.
    set -l session
    command -q rex; and set session (_rw_session $branch)

    # Leave the worktree before it is unlinked, so this shell is not one of the
    # processes found below.
    if string match -q "$target*" (pwd)
        cd $main
    end

    # 1. Stop everything still running in the checkout.
    _hw_stop_procs $target

    # 2. Repo-owned teardown (salvage docs, drop DB). Fatal on purpose: it
    # carries gitignored docs/ back into the main checkout.
    if test -x "$main/.herdr/teardown.sh"
        "$main/.herdr/teardown.sh" $target $branch; or return 1
    end

    # 3. Remove the checkout, then the branch and the empty parent dirs.
    set -l removed 0
    _hw_remove_checkout $main $target; or set removed 1
    if test $removed -eq 0
        test "$branch" != HEAD; and git -C $main branch -D $branch
        _hw_prune_parents $main $target
        echo "rw-rm: removed $target"
    else
        echo "rw-rm: $branch kept, the checkout is still on disk" >&2
    end

    # 4. Kill the Rex session LAST. When rw-rm runs from a pane inside that
    # session this kills the shell, so nothing may follow it. Step 1 often
    # empties the session already, and Rex closes an empty session by itself.
    if test -n "$session"; and rex session inspect $session >/dev/null 2>&1
        rex kill $session
    end
    return $removed
end
