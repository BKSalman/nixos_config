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
      xwayland-satellite
    ];

    programs.niri.enable = true;

    wayland.enable = true;
  };
}
