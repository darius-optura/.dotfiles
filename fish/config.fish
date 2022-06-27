if status is-interactive
    # Commands to run in interactive sessions can go here
end

# aliases  
alias vim="nvim"
alias cat="bat"
alias grep='grep --colour=auto'
alias egrep='egrep--colour=auto'
alias la='ls -a'
alias ll='ls -l'
alias lal='ls -al'
alias dirs='dirs -v'
alias cat='bat'
alias gg='lazygit'
alias python='python3'
alias simulator='open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'
alias scratch='nvim +noswapfile +"set buftype=nofile" +"set bufhidden=hide"'
alias k='kubectl'
alias klf='kubectl logs -f'
alias kp='kubectl get pods'
alias kfw='kubectl port-forward'
alias kd='kubectl describe'
alias tks='tmux kill-session -t'
alias tls='tmux list-sessions'
alias tns='tmux new-session -ds'
alias lzd='lazydocker'
# env variables
export STARSHIP_CONFIG=$HOME/.config/starship/starship.toml
 
export GOPATH=$HOME/Incubator/Go
export GOROOT="/usr/local/opt/go/libexec"
#export GO111MODULE=on
export PATH="$PATH:$GOPATH/bin:$GOROOT/bin"

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export PATH="$HOME/.gcloud/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export CLOUDSDK_PYTHON=python3

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

export BAT_THEME="Catppuccin"
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"

export KUBECONFIG="./kubeconfig.yml"


starship init fish | source
zoxide init fish | source
# The next line updates PATH for the Google Cloud SDK.
if [ -f '$HOME/.gcloud/path.fish.inc' ]; . '$HOME/.gcloud/path.fish.inc'; end
