{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    leftwm.enable = lib.mkEnableOption "enable leftwm";
  };

  config = lib.mkIf config.leftwm.enable {
    x11.enable = true;

    services.xserver = {
      windowManager.leftwm.enable = true;
      displayManager.defaultSession = "none+leftwm";
    };

    environment.systemPackages = with pkgs; [
      networkmanagerapplet
      haskellPackages.greenclip
      feh
      pulseaudio
    ];
  };
}
