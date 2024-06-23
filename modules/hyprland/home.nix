{lib, ...}: {
  imports = [
    # ./config.nix
  ];

  options = {
    hyprland.enable = lib.mkEnableOption "Enable hyprland configuration";
  };
}
