{
  config,
  pkgs,
  lib,
  ...
}: let
  jay-unstable = pkgs.jay.overrideAttrs (final: prev: rec {
    version = "unstable";
    src = pkgs.fetchFromGitHub {
      owner = "mahkoh";
      repo = "jay";
      rev = "f94f199ab12a4545a455a04aec11ec84b62f7c27";
      sha256 = "sha256-eE1l9ZHOejP+UHf4lOTK7Nr5xwH/eXaM7SHXJRT/C7k=";
    };
    cargoDeps = prev.cargoDeps.overrideAttrs (_: {
      inherit src version;
      outputHash = "sha256-WEEAFr5lemyOfeIKC9Pvr9sYMz8rLO6k1BFgbxXJ0Pk=";
    });

    postInstall = ''
      install -D etc/jay.portal $out/share/xdg-desktop-portal/portals/jay.portal
      install -D etc/jay-portals.conf $out/share/xdg-desktop-portal/jay-portals.conf
    '';
  });
  jay-with-session = jay-unstable.overrideAttrs (final: prev: let
    session = pkgs.writeText "jay" ''
      [Desktop Entry]
      Name=Jay
      Exec=${jay-unstable}/bin/jay --log-level info run
      Type=Application
    '';
  in {
    postInstall =
      prev.postInstall
      + ''
        install -D ${session} $out/share/wayland-sessions/jay.desktop
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
