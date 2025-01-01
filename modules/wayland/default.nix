{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    wayland.enable = lib.mkEnableOption "enable wayland tools and tweaks";
  };

  config = lib.mkIf config.wayland.enable {
    environment.systemPackages = with pkgs; [
      wl-clipboard
    ];
  };
}
