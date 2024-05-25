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

    # services.displayManager.defaultSession = "none+leftwm";
    services.xserver = {
      windowManager.leftwm.enable = true;
    };

    environment.systemPackages = with pkgs; [
      networkmanagerapplet
      haskellPackages.greenclip
      feh
      pulseaudio
    ];
  };
}
