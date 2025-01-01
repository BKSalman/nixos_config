{...}: {
  imports = [
    ./uxplay.nix
    ./vm.nix
    ./x11
    ./wayland
    ./x11/leftwm
    ./jay
    ./sway
    ./hyprland
    ./cosmic
  ];
}
