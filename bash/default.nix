{ config, pkgs, ... }:
{
  programs.bash = {
    enable = true;
    shellAliases = {
      nd = "nix develop";
      sk = "screenkey -g 300x300+2700+790";
    };
    bashrcExtra = builtins.readFile ./.bashrc;
  };
}

