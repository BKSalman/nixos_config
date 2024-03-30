final: prev: {
  webcord = prev.webcord.overrideAttrs (old: rec {
    src = prev.fetchFromGitHub {
      owner = "kakxem";
      repo = "WebCord";
      rev = "e5c2ded3ee53b6397736a262bbec5d253375b745";
      sha256 = "sha256-oFQ7fVJysmVUlhRMPxg/0w7srnXXu7gZ/kxlJZ2OW3g=";
    };
    npmDepsHash = prev.pkgs.lib.fakeHash;
    buildInputs = with prev.pkgs;
      old.buildInputs
      ++ [
        wayland
        pipewire
      ];
    postFixup = ''
      makeWrapper $out/opt/ArmCord/armcord $out/bin/armcord \
            "''${gappsWrapperArgs[@]}" \
            --prefix XDG_DATA_DIRS : "${prev.pkgs.gtk3}/share/gsettings-schemas/${prev.pkgs.gtk3.name}/" \
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland --enable-features=UseOzonePlatform --enable-features=WebRTCPipeWireCapturer }}" \
            --prefix LD_LIBRARY_PATH : "${prev.pkgs.lib.makeLibraryPath buildInputs}" \
            --suffix PATH : ${prev.pkgs.lib.makeBinPath [prev.pkgs.xdg-utils]}

      substituteInPlace $out/share/applications/webcord.desktop \
            --replace /opt/ArmCord/ $out/bin/
    '';
  });
}
