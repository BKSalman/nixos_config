{ lib
, stdenv
, dpkg
, fetchurl
}:
stdenv.mkDerivation rec {
  pname = "huiontablet";
  version = "15.0.0.89.202205241352";

  src = fetchurl {
    url = "https://driverdl.huion.com/driver/Linux/HuionTablet_v${version}.x86_64.deb";
    sha256 = "sha256-J8XbJOsBssTRThcrhXDyFVydO7NhcbJe8Qlad/P2w4E=";
  };

  # buildInput = [

  # ];

  # nativeBuildInput = [

  # ];

  dontBuild = true;
  dontConfigure = true;

  unpackPhase = ''
    ${dpkg}/bin/dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out/lib
    cp -r usr/lib $out/lib/
  '';

  meta = {
    description = "Official Huion tablets driver";
    homepage = "https://www.huion.com";
    platforms = [ "x86_64-linux" ];
  };
}
