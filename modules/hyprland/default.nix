{
  lib,
  hyprland,
  config,
  pkgs,
  ...
}: {
  options = {
    hyprland.enable = lib.mkEnableOption "Enable hyprland";
  };

  config = lib.mkIf config.hyprland.enable {
    programs.hyprland = {
      enable = true;
      package = hyprland.packages.${pkgs.system}.hyprland;
    };

    environment.systemPackages = with pkgs; [
      wofi
      hyprpaper
      mako
      # swayidle
      # swaylock-effects
      waybar
    ];

    services.displayManager.sessionPackages = [
      pkgs.hyprland
    ];
  };
}
