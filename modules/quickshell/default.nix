{
  lib,
  pkgs,
  config,
  ...
}: {
  options = {
    quickshell.enable = lib.mkEnableOption "Enable Quickshell";
  };

  config = lib.mkIf config.quickshell.enable {
    environment.systemPackages = with pkgs; [
      kdePackages.qtbase
      kdePackages.qtdeclarative
      kdePackages.qtmultimedia

      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-libav
    ];

    security.pam.services.quickshell-lock = {
      text = ''
        auth include login
      '';
    };
  };
}
