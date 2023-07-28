{ pkgs
, ...
}:
{

  environment.systemPackages = with pkgs; [
    polybar
    (rofi.override { plugins = [ pkgs.rofi-emoji ]; })
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      # pkgs.xdg-desktop-portal-wlr
      # pkgs.xdg-desktop-portal-kde
      # pkgs.xdg-desktop-portal-hyprland
    ];
  };

  services.xserver = {
    libinput.touchpad.naturalScrolling = true;

    deviceSection = ''
        Option "TearFree" "true"
      '';
  };

  environment.sessionVariables = rec {
    # __GL_GSYNC_ALLOWED = "0";
    # __GL_VRR_ALLOWED = "0";
    # _JAVA_AWT_WM_NONREPARENTING = "1";
    PATH = [
      "$HOME/.local/bin/:$PATH"
    ];
  };
}

