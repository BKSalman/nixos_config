{ pkgs, ... }:
{
  home.file.".config/mpv/scripts/encode.lua".source = ./scripts/encode.lua;
  home.file.".config/mpv/input.conf".source = ./input.conf;
  home.file.".config/mpv/mpv.conf".source = ./mpv.conf;
}
