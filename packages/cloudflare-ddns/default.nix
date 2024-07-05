{
  python3,
  lib,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "cloudflare-ddns";

  version = "v1.0.3";

  src = ./.;

  propagatedBuildInputs = [
    (python3.withPackages (pythonPackages:
      with pythonPackages; [
        requests
      ]))
  ];

  installPhase = ''
    mkdir -p $out/bin
    pwd
    ls -la $src
    cp $src/cloudflare-ddns.py $out/bin/cloudflare-ddns
    chmod +x $out/bin/cloudflare-ddns
  '';

  dontUnpack = true;

  meta = with lib; {
    platforms = platforms.linux;
  };
}
