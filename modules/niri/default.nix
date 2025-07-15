{
  config,
  pkgs,
  lib,
  ...
}: {
  options = {
    niri.enable = lib.mkEnableOption "enable niri";
  };

  config = lib.mkIf config.niri.enable {
    environment.systemPackages = with pkgs; [
      fuzzel
      mako
      waybar
      xwayland-satellite
      blueman
    ];

    programs.niri.enable = true;

    wayland.enable = true;
  };
}
