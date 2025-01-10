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
      rev = "1ca5d43557e892749b2497cefc69675faa7290ba";
      sha256 = "sha256-VAg59hmI38hJzkh/Vtv6LjrqQFLaq7rIGtk9sfQe1TA=";
    };
    cargoDeps = prev.cargoDeps.overrideAttrs (_: {
      inherit src version;
      outputHash = "sha256-ay9Usb+noXjWz6bEYd1YwkMC4Bn8ioux8WLuoCqw/Ec=";
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
