{ config, pkgs, ... }:
{
  programs.bash = {
    enable = true;
    shellAliases = {
      nd = "nix develop";
      sk = "screenkey -g 300x300+2700+790";
      jc = "journalctl --output cat";
      switch = "sudo nixo-rebuild switch --flake .#";
    };
    bashrcExtra = builtins.readFile ./.bashrc;
  };
}

