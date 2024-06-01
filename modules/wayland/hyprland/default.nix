{
  lib,
  config,
  ...
}: {
  imports = [./config.nix];

  options = {
    hyprland.enable = lib.mkEnableOption "Enable hyprland home-manager module";
  };

  config = lib.mkIf config.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      xwayland = {
        enable = true;
        # hidpi = true;
      };
    };
  };
}
