{ config, pkgs, ... }:
{

  programs.bash = {
    shellAliases = {
      nd = "nix develop";
      switch = "sudo nixos-rebuild switch --flake .#";
    };
  };

}

