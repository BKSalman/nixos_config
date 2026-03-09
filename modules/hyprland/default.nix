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

    environment.etc."xdg/menus/applications.menu".source =
      "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

    environment.systemPackages = with pkgs; [
      (rofi.override {plugins = [pkgs.rofi-emoji];})
      hyprpaper
      grim
      grimblast
      hyprpicker
      cliphist
    ];

    services.displayManager.sessionPackages = [
      pkgs.hyprland
    ];
  };
}
