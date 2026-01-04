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

  config = lib.mkIf config.hyprland.enable {
    home.packages = with pkgs; [
      quickshell.packages."x86_64-linux".default
      kdePackages.qtdeclarative
    ];

    home.file.".config/quickshell" = {
      recursive = true;
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_config/modules/quickshell/config";
    };
  };
}
