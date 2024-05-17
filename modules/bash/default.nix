{...}: {
  home.file.".inputrc".source = ./.inputrc;

  home.file.".local/bin/switch" = {
    source = ./switch;
    executable = true;
  };

  # home.file.".bashrc".source = ./bash/.bashrc;

  programs.bash = {
    enable = true;
    shellAliases = {
      nd = "nix develop";
      ls = "eza --time-style=long-iso --group-directories-first --icons --no-permissions --no-user -l --git";
      ll = "eza --time-style=long-iso --group-directories-first --icons -la";
      cat = "bat";
      imwheel = "imwheel -b 45";
      sk = "screenkey -g 300x500+1520+600";
      db = "distrobox";
      wmdev = "Xephyr -br -ac -noreset -screen 1880x1000 :2";
      o = "xdg-open";
      update-input = "nix flake lock --update-input";
    };
    sessionVariables = {
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      MANROFFOPT = "-c";
      EDITOR = "hx";
    };
    enableCompletion = true;
    bashrcExtra = ''
      export PATH

      eval "$(starship init bash)"

      eval "$(zoxide init bash)"

      eval "$(direnv hook bash)"

      if command -v fzf-share >/dev/null; then
        source "$(fzf-share)/key-bindings.bash"
        source "$(fzf-share)/completion.bash"
      fi
    '';
  };
}
