{...}: {
  imports = [
    ./uxplay.nix
    ./vm.nix
    ./x11
    ./wayland
    ./x11/leftwm
    ./jay
    ./niri
    ./sway
    ./hyprland
    ./cosmic
    ./nix.nix
    ./ssh.nix
  ];
}
