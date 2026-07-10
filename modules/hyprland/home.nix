{
  lib,
  config,
  ...
}: {
  imports = [
    # ./config.nix
    ../../modules/quickshell/home.nix
  ];

  options = {
    hyprland.enable = lib.mkEnableOption "Enable hyprland configuration";
  };

  config = lib.mkIf config.hyprland.enable {
    quickshell.enable = true;

    home.file.".config/hypr/hyprland.lua" = {
      recursive = true;
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_config/modules/hyprland/hyprland.lua";
    };
  };
}
