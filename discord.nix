{ pkgs, ... }:

final: prev: let
  # commandLineArgs = toString [
  #   "--enable-accelerated-mjpeg-decode"
  #   "--enable-accelerated-video"
  #   "--enable-zero-copy"
  #   "--use-gl=desktop"
  #   "--disable-features=UseOzonePlatform"
  #   "--enable-features=VaapiVideoDecoder"
  # ];
  commandLineArgs = toString [
    "--enable-features=UseOzonePlatform"
    "--ozone-platform=wayland"
  ];
in {
  discord = let
    wrapped = pkgs.writeShellScriptBin "discord" (''
      exec ${pkgs.discord}/bin/discord ${commandLineArgs}
    '');
  in
    pkgs.symlinkJoin {
      name = "discord";
      paths = [
        wrapped
        pkgs.discord
      ];
    };
}
