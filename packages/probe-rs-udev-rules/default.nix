{
  lib,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "probe-rs-udev-rules";
  version = "0.1.0";

  src = ../.;

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/lib/udev/rules.d
    cp udev-rules/69-probe-rs.rules $out/lib/udev/rules.d/69-probe-rs.rules
  '';

  meta = with lib; {
    description = "udev rules for probe-rs";
  };
}
