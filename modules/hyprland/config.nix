{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.hyprland.enable {
    home.file.".config/hyprland/hyprland.conf".source = ./hyprland.conf;
  };
}
