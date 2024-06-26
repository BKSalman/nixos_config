{
  fetchzip,
  lib,
  rustPlatform,
  installShellFiles,
  makeWrapper,
}:
rustPlatform.buildRustPackage rec {
  pname = "helix";
  version = "23.03";

  # This release tarball includes source code for the tree-sitter grammars,
  # which is not ordinarily part of the repository.
  src = fetchzip {
    url = "https://github.com/helix-editor/helix/releases/download/${version}/helix-${version}-source.tar.xz";
    sha256 = "sha256-FtY2V7za3WGeUaC2t2f63CcDUEg9zAS2cGUWI0YeGwk=";
    stripRoot = false;
  };

  # Fix git dependency on tree-sitter
  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      # add hash of tree-sitter master branch
      "tree-sitter-0.20.9" = "sha256-/PaFaASOT0Z8FpipX5uiRCjnv1kyZtg4B9+TnHA0yTY=";
    };
  };

  nativeBuildInputs = [installShellFiles makeWrapper];

  postInstall = ''
    # not needed at runtime
    rm -r runtime/grammars/sources

    mkdir -p $out/lib
    cp -r runtime $out/lib
    installShellCompletion contrib/completion/hx.{bash,fish,zsh}
  '';
  postFixup = ''
    wrapProgram $out/bin/hx --set HELIX_RUNTIME $out/lib/runtime
  '';

  meta = with lib; {
    description = "A post-modern modal text editor";
    homepage = "https://helix-editor.com";
    license = licenses.mpl20;
    mainProgram = "hx";
    maintainers = with maintainers; [danth yusdacra];
  };
}
