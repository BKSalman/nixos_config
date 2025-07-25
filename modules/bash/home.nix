{pkgs, ...}: {
  home.file.".inputrc".source = ./.inputrc;

  home.file.".local/bin/switch" = {
    text = ''
      #!/usr/bin/env bash

      machine=$(echo "$1" | tr -d '[:space:]')

      set -e
      set -x
      ${pkgs.alejandra}/bin/alejandra . &> /dev/null
      ${pkgs.git}/bin/git dft $(find . -name '*.nix') $(find . -name '*.toml')
      echo "Rebuilding NixOS for $machine..."
      nh os switch ~/nixos_config --ask -H "$@"
      gen=$(nixos-rebuild list-generations | awk '$NF == "True" {printf "%s %s %s %s %s\n", $1, $2, $3, $4, $5}')
      ${pkgs.git}/bin/git commit -am "$gen"
    '';
    executable = true;
  };

  home.file.".local/bin/switch-home-server" = {
    source = ./switch-home-server;
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

      eval "$(starship init bash)"

      eval "$(zoxide init bash)"

      eval "$(direnv hook bash)"

      # eval "$(jay generate-completion bash)"

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
}
