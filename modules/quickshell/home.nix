{
  config,
  lib,
  ...
}: {
  options = {
    quickshell.enable = lib.mkEnableOption "Enable Quickshell";
  };

  config = lib.mkIf config.quickshell.enable {
    programs.quickshell.enable = true;

    home.file.".config/quickshell" = {
      recursive = true;
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_config/modules/quickshell/config";
    };
  };
}
