{ pkgs
, ...
}:

let
  dbus-hyprland-environment = pkgs.writeTextFile {
    name = "dbus-hyprland-environment";
    destination = "/bin/dbus-hyprland-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    '';
  };
in
{

  environment.systemPackages = with pkgs; [
    dbus-hyprland-environment
    wayland
    glib
    grim # screenshot functionality
    slurp # screenshot functionality
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    wlogout
    wlr-randr
    (rofi-wayland.override { plugins = [ pkgs.rofi-emoji ]; })
    swayidle
    swaylock-effects
    wayland
    hyprpaper
    mako
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      # pkgs.xdg-desktop-portal-wlr
      # pkgs.xdg-desktop-portal-kde
      # pkgs.xdg-desktop-portal-hyprland
    ];
  };

  programs.xwayland.enable = true;

  environment.sessionVariables = rec {
    __GL_GSYNC_ALLOWED = "0";
    __GL_VRR_ALLOWED = "0";
    WLR_DRM_NO_ATOMIC = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland,x11";
    WLR_NO_HARDWARE_CURSORS = "1";
    MOZ_ENABLE_WAYLAND = "1";
    WLR_BACKEND = "vulkan";
    WLR_RENDERER = "vulkan";
    # XCURSOR_SIZE = "24";
    NIXOS_OZONE_WL = "1";
    GTK_USE_PORTAL = "1";
    QT_QPA_PLATFORMTHEME="kde";
    PATH = [
      "$HOME/.local/bin/:$PATH"
    ];
  };

  # services.greetd = {
  #   enable = true;
  #   settings = rec {
  #     initial_session = {
  #       command = "Hyprland";
  #       user = "salman";
  #     };
  #     default_session = initial_session;
  #   };
  # };

  # environment.etc."greetd/environments".text = ''
  #   Hyprland
  # '';

}
