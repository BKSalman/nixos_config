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
      (sudo nixos-rebuild switch --flake ".#$machine" | tee nixos-switch.log) || (cat "nixos-switch.log" | grep --color error && false)
      gen=$(nixos-rebuild list-generations | grep current)
      ${pkgs.git}/bin/git commit -am "$gen"
    '';
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
