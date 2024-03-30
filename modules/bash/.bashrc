export PATH

export PATH=/home/salman/.surrealdb:$PATH

export MANPAGER="sh -c 'col -bx | bat -l man -p'" 

export MANROFFOPT="-c"

export EDITOR=hx

eval "$(starship init bash)"

eval "$(zoxide init bash)"

eval "$(direnv hook bash)"
