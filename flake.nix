{
  description = "Salman's System Configuration :)";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    unstable-channel.url = "github:nixos/nixpkgs/fbb4cdbf121e2de303c39333bdf20bc5c8aeb5f5";
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { nixpkgs, home-manager, unstable-channel, hyprland, ... }:
  let 
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
    };

    lib = nixpkgs.lib;

    unstable = import unstable-channel {
      inherit system;
      config = { allowUnfree = true; };
    };

    

  in
  {
    homeManagerConfigurations = {
      salman = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
        ];
        extraSpecialArgs = {inherit unstable;};
      };
    };

    nixosConfigurations = {
      # nixos is my hostname
      nixos = lib.nixosSystem {
        inherit system;

        modules = [
          ./system/configuration.nix
          hyprland.nixosModules.default {
            programs.hyprland.enable = true;
          }
        ];
      };
    };

  };
}
