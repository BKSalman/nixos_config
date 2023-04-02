final: prev: {
  mpvpaper = prev.mpvpaper.overrideAttr (old: {
    patches = (old.patches or []) ++ [
      ./mpvpaper.patch
    ];
  });
}

