function _hw_stop_procs --description 'stop the processes whose cwd sits inside a worktree checkout'
    # Usage: _hw_stop_procs <checkout-path>
    # A live process in the checkout breaks teardown twice over: it holds the
    # worktree DB open (db-drop fails) and it keeps writing into .svelte-kit
    # while git deletes the tree, which makes `git worktree remove` abort.
    set -l root (path resolve $argv[1])

    # Never signal this process or one of its parents: hw-rm is often driven by
    # an agent running in a pane of the very workspace being torn down.
    set -l keep $fish_pid
    set -l p $fish_pid
    while set -l pp (ps -o ppid= -p $p 2>/dev/null | string trim)
        test -n "$pp" -a "$pp" != 0; or break
        set -a keep $pp
        set p $pp
    end

    # `lsof -d cwd` scans the process table only (~0.2s). `lsof +D $root` would
    # walk every file in the checkout (~70k) and take minutes.
    set -l pids
    set -l pid
    set -l cmd
    for line in (lsof -d cwd -Fpcn 2>/dev/null)
        set -l tag (string sub -l 1 -- $line)
        set -l val (string sub -s 2 -- $line)
        if test "$tag" = p
            set pid $val
        else if test "$tag" = c
            # lsof reports itself, and it inherited this checkout as its cwd.
            set cmd $val
        else if test "$tag" = n
            if test "$cmd" != lsof
                if test "$val" = "$root"; or string match -q "$root/*" -- $val
                    contains -- $pid $keep; or contains -- $pid $pids; or set -a pids $pid
                end
            end
        end
    end

    test (count $pids) -eq 0; and return 0
    echo "hw-rm: stopping" (count $pids) "process(es) inside the checkout:" $pids

    kill $pids 2>/dev/null
    # Give them ~5s to close DB connections and file handles, then insist.
    for i in (seq 20)
        set pids (for pid in $pids
            kill -0 $pid 2>/dev/null; and echo $pid
        end)
        test (count $pids) -eq 0; and return 0
        sleep 0.25
    end
    kill -9 $pids 2>/dev/null
    sleep 0.5
end
