{
  lib,
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
    };

    environment.systemPackages = with pkgs; [
      (rofi.override {plugins = [pkgs.rofi-emoji];})
      hyprpaper
      grim
      grimblast
      hyprpicker
      # mako
      # swayidle
      # swaylock-effects
      waybar
    ];

    services.displayManager.sessionPackages = [
      pkgs.hyprland
    ];
  };
}
