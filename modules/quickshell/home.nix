{
  pkgs,
  config,
  quickshell,
  lib,
  ...
}: {
  options = {
    quickshell.enable = lib.mkEnableOption "Enable Quickshell";
  };

  config = lib.mkIf config.quickshell.enable {
    home.packages = with pkgs; [
      quickshell.packages."x86_64-linux".default

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

    home.file.".config/quickshell" = {
      recursive = true;
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_config/modules/quickshell/config";
    };
  };
}
