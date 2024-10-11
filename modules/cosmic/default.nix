{
  config,
  pkgs,
  lib,
  ...
}: {
  options = {
    cosmic.enable = lib.mkEnableOption "Enable COSMIC DE";
  };

  config = lib.mkIf config.cosmic.enable {
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

    environment.systemPackages = with pkgs; [
      cosmic-ext-applet-clipboard-manager
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-cosmic
      ];
    };
    programs.xwayland.enable = true;
  };
}
