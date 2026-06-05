{
  lib,
  config,
  pkgs,
  quickshell,
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
      extraPortals = with pkgs; [xdg-desktop-portal-hyprland];
    };

    environment.etc."xdg/menus/applications.menu".source = "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";
    systemd.user.services.drkonqi-coredump-launcher.unitConfig.ConditionEnvironment = "!XDG_CURRENT_DESKTOP=Hyprland";
    systemd.user.sockets.drkonqi-coredump-launcher.unitConfig.ConditionEnvironment = "!XDG_CURRENT_DESKTOP=Hyprland";

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

    services.hypridle.enable = true;
    systemd.user.services.hypridle.path = [quickshell.packages."x86_64-linux".default];

    environment.systemPackages = with pkgs; [
      mako
      hyprshutdown
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
