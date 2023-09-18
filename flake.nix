{
  description = "Salman's System Configuration :)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # hyprland = {
    #   url = "github:hyprwm/Hyprland";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # hyprland-contrib = {
    #   url = "github:hyprwm/contrib";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    prismlauncher = {
      url = "github:prismlauncher/prismlauncher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix = {
      url = "github:helix-editor/helix/23.05";
    };

    ytdlp-gui = {
      url = "github:bksalman/ytdlp-gui";
    };

    rust-overlay.url = "github:oxalica/rust-overlay/master";

    leftwm = {
      url = "github:leftwm/leftwm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs"; # override this repo's nixpkgs snapshot
    };

    eza = {
      url = "github:eza-community/eza";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, prismlauncher, rust-overlay, ytdlp-gui, helix, leftwm, nh, eza, ... }:
    let
      system = "x86_64-linux";

      tokyonight-gtk-overlay = final: prev: {
        tokyonight-gtk = prev.callPackage ./packages/tokyonight { };
      };

      evremap-overlay = final: prev: {
        evremap = prev.callPackage ./packages/evremap { };
      };

      webcord-overlay = final: prev: {
        webcord = prev.callPackage ./packages/webcord { };
      };

      insomnia-overlay = final: prev: {
        insomnia = prev.callPackage ./packages/insomnia { };
      };

      nh-overlay = final: prev: {
        nh = nh.packages.${system}.default;
      };

      nerdfonts-overlay = final: prev: {
        nerdfonts = prev.callPackage ./packages/nerdfonts { };
      };

      gf-overlay = final: prev: {
        gf = prev.callPackage ./packages/gf { };
      };

      eza-overlay = final: prev: {
        eza = eza.packages.${system}.default;
      };

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "python3.10-requests-2.29.0"
            "python3.10-cryptography-40.0.2"
            "python3.10-cryptography-40.0.1"
          ];
        };
        overlays = [
          # FIXME: remove after it gets fixed
          nerdfonts-overlay

          rust-overlay.overlays.default
          nh-overlay
          leftwm.overlays.default
          ytdlp-gui.overlay
          # hyprland-contrib.overlays.default
          # rust-overlay.overlays.default
          # helix.overlays.default
          prismlauncher.overlays.default
          # (insomnia-overlay)
          (import ./overlays/mpvpaper.nix)
          (eza-overlay)
          (gf-overlay)
          (tokyonight-gtk-overlay)
          (evremap-overlay)
          (webcord-overlay)
        ];
      };

      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations = {
        # nixos is my hostname
        nixos = lib.nixosSystem {
          inherit system pkgs;

          modules = [
            ./system/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.salman = {
                imports = [
                  ./home.nix
                  # hyprland.homeManagerModules.default
                ];
              };
              home-manager.extraSpecialArgs = { inherit helix; };
            }
          ];
        };
      };
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    };
}
