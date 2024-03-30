final: prev: {
  insomnia = let
    wrapped = prev.writeShellScriptBin "insomnia" ''
      exec ${prev.insomnia}/bin/insomnia --enable-features=UseOzonePlatform --ozone-platform=wayland
    '';
  in
    prev.symlinkJoin {
      name = "insomnia";
      paths = [
        wrapped
        prev.insomnia
      ];
    };
}
