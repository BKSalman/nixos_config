{
  fetchFromGitHub,
  lib,
  rustPlatform,
  pkgs,
}:
rustPlatform.buildRustPackage rec {
  pname = "evremap";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "wez";
    repo = pname;
    rev = "master";
    sha256 = "sha256-7fS42x+YLci9HG0IL58IBS4qxHLZdk3YlPHseZzJ/ag=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
  '';

  buildInputs = with pkgs; [
    autoconf
    automake
    libevdev
  ];

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  meta = with lib; {
    description = "A keyboard input remapper for Linux/Wayland systems, written by @wez";
    homepage = "https://github.com/wez/evremap";
    license = licenses.mit;
    mainProgram = pname;
    maintainers = with maintainers; [bksalman];
  };
}
