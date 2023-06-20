final: prev: {
  distrobox = prev.distrobox.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "89luca89";
      repo = "distrobox";
      rev = "main";
      sha256 = "sha256-GPhYZYmYoLcwN6e1wwEZNnih/B78MdMWryZxYGW2ID0=";
    };
  });
}


