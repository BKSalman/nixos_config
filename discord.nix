final: prev: {
  discord = let
    wrapped = prev.writeShellScriptBin "discord" (''
      exec ${prev.discord}/bin/discord --enable-features=UseOzonePlatform --ozone-platform=wayland
    '');
  in
    prev.symlinkJoin {
      name = "discord";
      paths = [
        wrapped
        prev.discord
      ];
    };
}
