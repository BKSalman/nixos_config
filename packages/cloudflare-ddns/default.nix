{
  python3,
  lib,
  fetchFromGitHub,
  stdenv,
}:
stdenv.mkDerivation rec {
  pname = "cloudflare-ddns";

  version = "v1.0.3";

  src = fetchFromGitHub {
    owner = "timothymiller";
    repo = pname;
    rev = "4ea9ba5745ab65ffd250091e865d140675730f82";
    sha256 = "sha256-fTWx+6GP6x33DA5gOA+7dNIThGkP0Eka9qVdNtz9XAo=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    requests
  ];

  installPhase = ''
    mkdir -p $out/bin
    ls -la
    cp cloudflare-ddns.py $out/bin/cloudflare-ddns
    chmod +x $out/bin/cloudflare-ddns
  '';

  meta = with lib; {
    platforms = platforms.linux;
  };
}
