{ config, pkgs, ... }:
{
  programs.bash = {
    enable = true;
    shellAliases = {
      nd = "nix develop";
    };
    bashrcExtra = builtins.readFile ./.bashrc;
  };
}

