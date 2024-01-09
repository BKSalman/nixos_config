{ pkgs, ... }:
{
  services.xserver = {
    displayManager.sessionPackages = [ pkgs.hyprland ];
  };

  environment.systemPackages = with pkgs; [
    egl-wayland
    grimblast
    grim # screenshot functionality
    slurp # screenshot functionality
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    wlogout
    wlr-randr
    (rofi-wayland.override { plugins = [ pkgs.rofi-emoji ]; })
    swayidle
    swaylock-effects
    hyprpaper
    mako
    element-desktop-wayland
  ];

  xdg.portal = {
    enable = true;
    config.common.default = "gtk";
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  programs.xwayland.enable = true;

  environment.sessionVariables = {
    __GL_GSYNC_ALLOWED = "0";
    __GL_VRR_ALLOWED = "0";
    WLR_DRM_NO_ATOMIC = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    # TODO: put back later
    # QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland,x11";
    WLR_NO_HARDWARE_CURSORS = "1";
    MOZ_ENABLE_WAYLAND = "1";
    WLR_BACKEND = "vulkan";
    WLR_RENDERER = "vulkan";
    XCURSOR_SIZE = "24";
    NIXOS_OZONE_WL = "1";
    GTK_USE_PORTAL = "1";
    PATH = [
      "$HOME/.local/bin/:$PATH"
    ];
  };

  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "buddaraysh";
        user = "salman";
      };
      default_session = initial_session;
    };
  };

  environment.etc."greetd/environments".text = ''
    buddaraysh
  '';
}
