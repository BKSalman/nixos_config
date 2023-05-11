final: prev: {
  nerdfonts = prev.nerdfonts.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      # FIXME: remove when nerd fonts are fixed
      (prev.fetchpatch {
        url = "https://github.com/jarun/nnn/commit/20e944f5e597239ed491c213a634eef3d5be735e.patch";
        hash = "sha256-RxG3AU8i3lRPCjRVZPnej4m1No/SKtsHwbghj9JQ7RQ=";
      })
    ];
  });
}

