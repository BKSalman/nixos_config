export PATH

export PATH=$PATH:/home/salman/.surrealdb
export PATH=$PATH:$HOME/go/bin

export MANPAGER="sh -c 'col -bx | bat -l man -p'" 

export MANROFFOPT="-c"

export EDITOR=hx

eval "$(starship init bash)"

eval "$(zoxide init bash)"

eval "$(direnv hook bash)"

eval "$(zellij setup --generate-auto-start bash)"
