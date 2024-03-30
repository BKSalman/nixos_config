{
  lib,
  config,
  ...
}: {
  options = {
    hyprland.enable = lib.mkEnableOption "Enable hyprland home-manager module";
  };

  config = lib.mkIf config.hyprland.enable {
    imports = [./config.nix];

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland = {
        enable = true;
        # hidpi = true;
      };
      enableNvidiaPatches = true;
    };
  };
}
