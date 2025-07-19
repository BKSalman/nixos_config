{
  config,
  pkgs,
  lib,
  nixos-cosmic,
  ...
}: {
  options = {
    cosmic.enable = lib.mkEnableOption "Enable COSMIC DE";
  };

  config = lib.mkIf config.cosmic.enable {
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

    environment.systemPackages = [
      nixos-cosmic.packages."x86_64-linux".cosmic-ext-applet-clipboard-manager
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
