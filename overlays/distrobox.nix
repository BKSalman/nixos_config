final: prev: {
  distrobox = prev.distrobox.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "89luca89";
      repo = "distrobox";
      rev = "main";
      sha256 = "sha256-0bMYxpTJ5EbdE1A4WuDeqFwSsZYsRhGVtRlRYLla850=";
    };
  });
}


