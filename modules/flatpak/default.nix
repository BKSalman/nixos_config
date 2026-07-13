{
  pkgs,
  nixpkgs-flatpak,
  ...
}: {
  services.flatpak = {
    enable = true;
    # TEMPORARY: pin Flatpak itself to 1.16.6 via nixpkgs-flatpak (see flake.nix).
    # Flatpak >=1.18.0 leaks the NixOS host environment into the sandbox and breaks
    # glycin-svg icon loading (e.g. OpenDeck). Remove once
    # https://github.com/flatpak/flatpak/issues/6721 lands in nixpkgs.
    package = nixpkgs-flatpak.legacyPackages.${pkgs.system}.flatpak;
  };
}

