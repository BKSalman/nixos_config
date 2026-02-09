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
  };
}
