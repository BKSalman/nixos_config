{pkgs, ...}: {
  home.file.".inputrc".source = ./.inputrc;

  # home.file.".bashrc".source = ./bash/.bashrc;

  programs.bash = {
    enable = true;
    shellAliases = {
      nd = "nix develop";
      ls = "eza --time-style=long-iso --group-directories-first --icons --no-permissions --no-user -l --git";
      ll = "eza --time-style=long-iso --group-directories-first --icons -la";
      cat = "bat";
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
      PAGER = "less -FRX";
      STEEL_LSP_HOME = "/home/salman/.config/steel-lsp/";
    };
    enableCompletion = true;
    bashrcExtra = ''
      export PATH

      eval "$(direnv hook bash)"

      # eval "$(jay generate-completion bash)"

      # eval "$(zellij setup --generate-auto-start bash)"

      if command -v fzf-share >/dev/null; then
        source "$(fzf-share)/key-bindings.bash"
        source "$(fzf-share)/completion.bash"
      fi

      export PATH="$PATH:$HOME/.cargo/bin"

      function y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
          fi
          rm -f -- "$tmp"
        }
    '';
  };

  home.file.".config/starship.toml".source = ../../modules/starship.toml;

  programs.starship.enable = true;

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };
}
