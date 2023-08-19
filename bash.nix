{ config, pkgs, ... }:
{
  home.file.".inputrc".source = ./bash/.inputrc;

  home.file.".bashrc".source = ./bash/.bashrc;

  programs.bash = {
    shellAliases = {
      nd = "nix develop";
      switch = "sudo nixos-rebuild switch --flake .#";
    };
  };
}

