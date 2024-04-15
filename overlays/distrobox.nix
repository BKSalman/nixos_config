final: prev: {
  distrobox = prev.distrobox.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "89luca89";
      repo = "distrobox";
      rev = "main";
      sha256 = "sha256-mSka8QyoLjnaVEP23TtyzbPTBHDlnrSomVZdfw4PPng=";
    };
  });
}
