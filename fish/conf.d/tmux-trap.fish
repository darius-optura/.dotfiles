function __trap_exit_tmux
  if test (tmux list-windows | wc -l) -gt 1 
    exit
  end
  if test (tmux list-panes | wc -l) -gt 1 
    exit
  end

  tmux switch -t default
end

if status --is-interactive
	trap __trap_exit_tmux SIGINT INT EXIT
end
