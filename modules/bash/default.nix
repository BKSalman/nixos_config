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
    enableCompletion = true;
    bashrcExtra = builtins.readFile ./.bashrc;
  };
}
