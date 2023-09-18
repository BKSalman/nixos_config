{ config, pkgs, ... }:
{
  home.file.".inputrc".source = ./bash/.inputrc;

  # home.file.".bashrc".source = ./bash/.bashrc;

  programs.bash = {
    enable = true;
    shellAliases = {
      nd = "nix develop";
      switch = "sudo nixos-rebuild switch --flake .#";
      ls = "eza --time-style=long-iso --group-directories-first --icons --no-permissions --no-user -l --git";
      ll = "eza --time-style=long-iso --group-directories-first --icons -la";
      cat = "bat";
      imwheel = "imwheel -b 45";
      sk = "screenkey -g 300x500+1520+600";
    };
    enableCompletion = true;
    bashrcExtra = builtins.readFile ./bash/.bashrc;
  };
}
