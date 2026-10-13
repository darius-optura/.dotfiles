function _hw_remove_checkout --description 'unregister a linked worktree and delete its checkout'
    # Usage: _hw_remove_checkout <main-checkout> <worktree-path>
    set -l main (path resolve $argv[1])
    set -l target (path resolve $argv[2])

    # The rm below must only ever reach a checkout under the repo's own worktree
    # root, never the main checkout or anything outside it.
    set -l root "$main/.claude/worktrees"
    if not string match -q "$root/*" -- $target
        echo "hw-rm: $target is not under $root, refusing to delete it" >&2
        return 1
    end

    # `git worktree remove` deletes the tree in one recursive walk that STOPS at
    # the first entry it cannot unlink, so one busy file leaves all ~70k of them
    # behind -- yet it still unregisters the worktree and exits 1. Finish the
    # delete here, and prune the admin dir whichever way git went.
    # --force twice: the second one overrides a `git worktree lock` (supacode
    # locks every worktree it adopts).
    if not git -C $main worktree remove --force --force $target 2>/dev/null
        echo "hw-rm: git could not remove the checkout, deleting $target directly"
    end
    for i in 1 2
        test -e $target; or break
        rm -rf $target
    end
    git -C $main worktree prune

    if test -e $target
        echo "hw-rm: $target still exists" >&2
        return 1
    end
end
