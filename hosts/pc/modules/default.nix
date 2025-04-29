{...}: {
  imports = [
    ./virtual/vfio.nix
    ./nvidia.nix
    ./sadmadbotlad.nix
    ./sops.nix
  ];
}
