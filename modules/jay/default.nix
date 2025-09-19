{
  config,
  pkgs,
  lib,
  ...
}: let
  jay-with-session = pkgs.jay.overrideAttrs (final: prev: {
    postInstall =
      prev.postInstall
      + ''
        install -D $src/etc/jay.desktop $out/share/wayland-sessions/jay.desktop
      '';
    passthru.providedSessions = ["jay"];
  });
in {
  options = {
    jay.enable = lib.mkEnableOption "Enable jay";
  };

  config = lib.mkIf config.jay.enable {
    services.displayManager.defaultSession = "jay";
    services.displayManager.sessionPackages = [
      jay-with-session
    ];
    environment.systemPackages = with pkgs; [
      jay-with-session
      bemenu
      grim
      slurp
      wl-clipboard
    ];
    xdg.portal = {
      enable = true;
    };
    programs.xwayland.enable = true;
  };
}
