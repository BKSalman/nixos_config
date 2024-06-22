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
      sha256 = "sha256-2Vp0r3m6J1mDVd0ulP7FYoCbZNrk7PBZGv/BZQe3ILk=";
    };
    cargoDeps = prev.cargoDeps.overrideAttrs (_: {
      inherit src version;
      outputHash = "sha256-WEEAFr5lemyOfeIKC9Pvr9sYMz8rLO6k1BFgbxXJ0Pk=";
    });
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
    environment.systemPackages = [
      jay-with-session
    ];
  };
}
