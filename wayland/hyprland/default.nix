{ pkgs, ... }: {
  imports = [
    ./config.nix
    ../../waybar
  ];

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
