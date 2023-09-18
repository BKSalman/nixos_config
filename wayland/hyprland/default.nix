{ pkgs, ... }: {
  imports = [ ./config.nix ];

  home.packages = with pkgs; [
    grimblast
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
      # hidpi = true;
    };
  };
}
