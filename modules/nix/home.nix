{pkgs, ...}: {
  home.file.".local/bin/switch" = {
    text = ''
      #!/usr/bin/env bash

      machine=$(echo "$1" | tr -d '[:space:]')

      set -e
      set -x
      ${pkgs.alejandra}/bin/alejandra . &> /dev/null
      ${pkgs.git}/bin/git dft $(find . -name '*.nix') $(find . -name '*.toml')
      echo "Rebuilding NixOS for $machine..."
      nh os switch ~/nixos_config --ask -H "$@"
      gen=$(nixos-rebuild list-generations | awk '$NF == "True" {printf "%s %s %s %s %s\n", $1, $2, $3, $4, $5}')
      ${pkgs.git}/bin/git commit -am "$gen"
    '';
    executable = true;
  };

  home.file.".local/bin/switch-home-server" = {
    source = ./switch-home-server;
    executable = true;
  };
}
