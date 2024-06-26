{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    x11.enable = lib.mkEnableOption "enable x11";
  };

  config = lib.mkIf config.x11.enable {
    environment.systemPackages = with pkgs; [
      polybar
      (rofi.override {plugins = [pkgs.rofi-emoji];})
      dunst
      element-desktop
    ];

    xdg.portal = {
      enable = true;
      # xdgOpenUsePortal = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common.default = "*";
    };

    services.xserver = {
      libinput.touchpad.naturalScrolling = true;

      deviceSection = ''
        Option "TearFree" "true"
      '';
    };

    environment.sessionVariables = {
      # __GL_GSYNC_ALLOWED = "0";
      # __GL_VRR_ALLOWED = "0";
      # _JAVA_AWT_WM_NONREPARENTING = "1";
      PATH = [
        "$HOME/.local/bin/:$PATH"
        "$HOME/.cargo/bin/:$PATH"
      ];
    };

    programs.slock.enable = true;

    services.picom = {
      enable = true;
    };
  };
}
