{ ... }: {

  home.file.".config/hypr/idle.sh".source = ./idle.sh;

  wayland.windowManager.hyprland.extraConfig = builtins.readFile ./hyprland.conf;
}
