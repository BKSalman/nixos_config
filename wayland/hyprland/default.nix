{...}: {
  imports = [
    ./config.nix
    ../../waybar
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
      # hidpi = true;
    };
  };
}
