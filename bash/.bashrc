# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

export GOPATH="$HOME/go"

export PATH="$GOPATH/bin:$PATH"

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc
. "$HOME/.cargo/env"

export PATH=/home/salman/.surrealdb:$PATH

alias ls='exa --time-style=long-iso --group-directories-first --icons --no-permissions --no-user -l --git'

alias ll="exa --time-style=long-iso --group-directories-first --icons -la"

alias cat=bat

alias imwheel="imwheel -b 45"

export MANPAGER="sh -c 'col -bx | bat -l man -p'" 

export EDITOR=hx

eval "$(zoxide init bash)"

eval "$(starship init bash)"

eval "$(direnv hook bash)"

alias leftwm-dev="~/.cargo/bin/leftwm"
