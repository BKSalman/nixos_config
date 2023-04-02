final: prev: {
  mpvpaper = prev.mpvpaper.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ./mpvpaper.patch
    ];
  });
}

