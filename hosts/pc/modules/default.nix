{...}: {
  imports = [
    ./virtual/vfio.nix
    ./nextcloud.nix
    ./nvidia.nix
    ./sadmadbotlad.nix
    ./sops.nix
  ];
}
