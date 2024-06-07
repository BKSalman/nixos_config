{
  description = "Salman's System Configuration :)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
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
      url = "github:helix-editor/helix/24.03";
    };

    rust-overlay.url = "github:oxalica/rust-overlay";

    ytdlp-gui = {
      url = "github:bksalman/ytdlp-gui";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    arion = {
      url = "github:hercules-ci/arion";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    hyprland-contrib,
    prismlauncher,
    helix,
    rust-overlay,
    ytdlp-gui,
    leftwm,
    manmap,
    sadmadbotlad,
    eza,
    arion,
    sops-nix,
    ...
  }: let
    system = "x86_64-linux";

    tokyonight-gtk-overlay = final: prev: {
      tokyonight-gtk = prev.callPackage ./packages/tokyonight {};
    };

    evremap-overlay = final: prev: {
      evremap = prev.callPackage ./packages/evremap {};
    };

    webcord-overlay = final: prev: {
      webcord = prev.callPackage ./packages/webcord {};
    };

    insomnia-overlay = final: prev: {
      insomnia = prev.callPackage ./packages/insomnia {};
    };

    nerdfonts-overlay = final: prev: {
      nerdfonts = prev.callPackage ./packages/nerdfonts {};
    };

    obs-text-pango-overlay = final: prev: {
      obs-text-pango = prev.callPackage ./packages/obs-plugins/text-pango.nix {};
    };

    davinci-resolve-overlay = final: prev: {
      davinci-resolve = prev.callPackage ./packages/davinci-resolve {};
    };

    eza-overlay = final: prev: {
      eza = eza.packages.${system}.default;
    };

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "python-2.7.18.8"
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
        eza-overlay
        obs-text-pango-overlay
        davinci-resolve-overlay
        insomnia-overlay
        # (import ./overlays/mpvpaper.nix)
        (import ./overlays/distrobox.nix)
        tokyonight-gtk-overlay
        evremap-overlay
        webcord-overlay
      ];
    };

    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      pc = lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {inherit sadmadbotlad;};

        modules = [
          ./hosts/pc/configuration.nix

          sops-nix.nixosModules.sops
          # xremap-flake.nixosModules.default

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.salman = {
              imports = [
                ./hosts/pc/home.nix
              ];
            };
            home-manager.extraSpecialArgs = {inherit helix sadmadbotlad;};
          }
        ];
      };
      laptop = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/laptop/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.salman = {
              imports = [
                ./hosts/laptop/home.nix
              ];
            };
            home-manager.extraSpecialArgs = {inherit helix;};
          }
        ];
      };
      home-server = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/home-server/configuration.nix
          sops-nix.nixosModules.sops
          arion.nixosModules.arion
        ];
      };
    };
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
  };
}
