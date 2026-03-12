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
      withUWSM = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
    };

    environment.etc."xdg/menus/applications.menu".source =
      "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

    environment.etc = {
      "xdg/qt5ct/qt5ct.conf".text = ''
        [Appearance]
        style=Breeze
      '';
      "xdg/qt6ct/qt6ct.conf".text = ''
        [Appearance]
        style=Breeze
      '';
    };

    environment.systemPackages = with pkgs; [
      (rofi.override {plugins = [pkgs.rofi-emoji];})
      hyprpaper
      grim
      grimblast
      hyprpicker
      cliphist
      libsForQt5.qt5ct
      kdePackages.qt6ct
      kdePackages.breeze
    ];

    services.displayManager.sessionPackages = [
      pkgs.hyprland
    ];
  };
}
