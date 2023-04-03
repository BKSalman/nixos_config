{ fetchFromGitHub, fakeSha256, lib, rustPlatform, installShellFiles, makeWrapper, libevdev }:

rustPlatform.buildRustPackage rec {
  pname = "evremap";
  version = "0.1.0";

  # This release tarball includes source code for the tree-sitter grammars,
  # which is not ordinarily part of the repository.
  src = fetchFromGitHub {
    owner = "wez";
    repo = pname;
    rev = "master";
    sha256 = fakeSha256;
  };

  nativeBuildInputs = [
    libevdev

    installShellFiles
    makeWrapper
  ];

  # postFixup = ''
  #   wrapProgram $out/bin/hx --set HELIX_RUNTIME $out/lib/runtime
  # '';

  meta = with lib; {
    description = "A keyboard input remapper for Linux/Wayland systems, written by @wez";
    homepage = "https://github.com/wez/evremap";
    license = licenses.mit;
    mainProgram = pname;
    maintainers = with maintainers; [ bksalman ];
  };
}
