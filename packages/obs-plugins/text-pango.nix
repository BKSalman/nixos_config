{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, obs-studio
, pango
}:

stdenv.mkDerivation {
  pname = "obs-text-pango";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "kkartaltepe";
    repo = "obs-text-pango";
    rev = "master";
    sha256 = "sha256-7jvRD1tT4w5C3UvrN9HmdTZZgn1BFdjqauXiEmxEEWs=";
  };

  cmakeFlags = [
    "-DOBS_DIR=${obs-studio.src}"
  ];

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ obs-studio pango ];

  postInstall = ''
    mkdir -p $out/lib/obs-plugins
    mv $out/bin/libtext-pango.so $out/lib/obs-plugins/
    rm -rf $out/bin
  '';

  meta = with lib; {
    description = "Text Source using Pango for OBS Studio";
    homepage = "https://github.com/kkartaltepe/obs-text-pango";
    license = licenses.gpl2;
    maintainers = with maintainers; [ bksalman ];
    platforms = [ "x86_64-linux" ];
  };
}
