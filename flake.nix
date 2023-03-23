{
  description = "Salman's System Configuration :)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    master-channel.url = "github:nixos/nixpkgs/master";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { nixpkgs, home-manager, master-channel, ... }:
  let 
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
    };

    lib = nixpkgs.lib;

    masterpkgs = import master-channel {
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
        extraSpecialArgs = {inherit masterpkgs;};
      };
    };

    nixosConfigurations = {
      # nixos is my hostname
      nixos = lib.nixosSystem {
        inherit system;

        modules = [
          ./system/configuration.nix
          # hyprland.nixosModules.default {
          #   programs.hyprland.enable = true;
          # }
        ];
        specialArgs = {inherit masterpkgs;};
      };
    };
  };
}
