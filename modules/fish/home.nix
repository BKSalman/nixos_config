{pkgs, ...}: {
  programs.fish = {
    enable = true;
    shellAliases = {
      ls = "eza --time-style=long-iso --group-directories-first --icons --no-permissions --no-user -l --git";
      ll = "eza --time-style=long-iso --group-directories-first --icons -la";
      cat = "bat";
      wmdev = "Xephyr -br -ac -noreset -screen 1880x1000 :2";
    };

    shellAbbrs = {
      nd = "nix develop";
      sk = "screenkey -g 300x500+1520+600";
      db = "distrobox";
      o = "xdg-open";
    };

    shellInit = ''
      # Environment variables
      set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
      set -gx MANROFFOPT "-c"
      set -gx EDITOR "hx"
      set -gx PAGER "less -FRX"
      set -gx STEEL_LSP_HOME "/home/salman/.config/steel-lsp/"
    '';

    interactiveShellInit = ''
      zoxide init fish | source
      direnv hook fish | source

      # keybinds
      fish_vi_key_bindings

      # some Helix navigation
      bind -M default gh beginning-of-line
      bind -M default gl end-of-line
      bind -M default gs beginning-of-line forward-word backward-char
      bind -M default ge end-of-line
      bind -M visual gh beginning-of-line
      bind -M visual gl end-of-line
      bind -M visual gs beginning-of-line forward-word backward-char
      bind -M visual ge end-of-line
      bind -M default alt-p prevd-or-backward-word
      bind -M default alt-n nextd-or-forward-word

      function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
          builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
      end
    '';
  };

  # use fish only for interactive shells (not login shell) because it's not posix, and could break something
  programs.bash.initExtra  = ''
    if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
    then
      shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
      exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
    fi

    # Only initialize starship if we didn't exec to fish
    eval "$(starship init bash)"
  '';

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
