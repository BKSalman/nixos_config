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

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    prismlauncher = {
      url = "github:prismlauncher/prismlauncher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix = {
      url = "github:helix-editor/helix/23.05";
    };

    rust-overlay.url = "github:oxalica/rust-overlay";

    ytdlp-gui.url = "github:bksalman/ytdlp-gui";

    leftwm = {
      url = "github:leftwm/leftwm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    manmap = {
      url = "github:bksalman/manmap";
    };

    sadmadbotlad = {
      url = "github:bksalman/sadmadbotlad";
    };

    eza = {
      url = "github:eza-community/eza";
    };
  };

  outputs = { nixpkgs, home-manager, hyprland-contrib, prismlauncher, helix, rust-overlay, ytdlp-gui, leftwm, manmap, sadmadbotlad, eza, ... }:
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

      nerdfonts-overlay = final: prev: {
        nerdfonts = prev.callPackage ./packages/nerdfonts { };
      };

      obs-text-pango-overlay = final: prev: {
        obs-text-pango = prev.callPackage ./packages/obs-plugins/text-pango.nix { };
      };

      davinci-resolve-overlay = final: prev: {
        davinci-resolve = prev.callPackage ./packages/davinci-resolve { };
      };

      eza-overlay = final: prev: {
        eza = eza.packages.${system}.default;
      };

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "python-2.7.18.6"
          ];
        };
        overlays = [
          # FIXME: remove after it gets fixed
          nerdfonts-overlay


          manmap.overlay
          leftwm.overlays.default
          ytdlp-gui.overlay
          hyprland-contrib.overlays.default
          rust-overlay.overlays.default
          # helix.overlays.default
          prismlauncher.overlays.default
          (eza-overlay)
          (obs-text-pango-overlay)
          (davinci-resolve-overlay)
          (insomnia-overlay)
          (import ./overlays/mpvpaper.nix)
          (import ./overlays/distrobox.nix)
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
          specialArgs = { inherit sadmadbotlad; };

          modules = [
            ./system/configuration.nix

            # xremap-flake.nixosModules.default

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
