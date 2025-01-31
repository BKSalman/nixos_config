{...}: {
  config.nix = {
    settings = rec {
      trusted-substituters = [
        "https://cosmic.cachix.org/"
        "https://helix.cachix.org/"
        "https://prismlauncher.cachix.org/"
      ];
      substituters = trusted-substituters;
      trusted-public-keys = [
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
        "prismlauncher.cachix.org-1:9/n/FGyABA2jLUVfY+DEp4hKds/rwO+SCOtbOkDzd+c="
      ];
      trusted-users = [
        "@wheel"
        "salman"
        "root"
      ];
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
