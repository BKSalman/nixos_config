{ default
, pkgs
, ...
}: {
  imports = [ ./config.nix ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
      # hidpi = true;
    };
    nvidiaPatches = true;
  };
}
