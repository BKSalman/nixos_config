{
  description = "Salman's System Configuration :)";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixos-cosmic/nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixos-cosmic/nixpkgs";
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
      url = "github:mattwparas/helix/steel-event-system";
    };

    rust-overlay.url = "github:oxalica/rust-overlay";

    ytdlp-gui = {
      url = "github:bksalman/ytdlp-gui";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    prayer-times-applet = {
      url = "github:bksalman/prayer-times-applet";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    leftwm = {
      url = "github:leftwm/leftwm";
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

    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    };

    # TODO: remove when upstreamed to nixpkgs
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";

    # proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    reaction-roles-bot = {
      url = "github:bksalman/reaction_roles";
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
    prayer-times-applet,
    leftwm,
    manmap,
    sadmadbotlad,
    eza,
    arion,
    sops-nix,
    hyprland,
    nixos-cosmic,
    # proxmox-nixos,
    nixos-hardware,
    reaction-roles-bot,
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

    nerdfonts-overlay = final: prev: {
      nerdfonts = prev.callPackage ./packages/nerdfonts {};
    };

    obs-text-pango-overlay = final: prev: {
      obs-text-pango = prev.callPackage ./packages/obs-plugins/text-pango.nix {};
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

          # FIXME: remove after https://github.com/NixOS/nixpkgs/issues/360592
          # and https://github.com/NixOS/nixpkgs/issues/326335 are sorted out
          "aspnetcore-runtime-6.0.36"
          "aspnetcore-runtime-wrapped-6.0.36"
          "dotnet-sdk-6.0.428"
          "dotnet-sdk-wrapped-6.0.428"
        ];
      };
      overlays = [
        # FIXME: remove after it gets fixed
        # nerdfonts-overlay

        manmap.overlay
        leftwm.overlays.default
        ytdlp-gui.overlay
        reaction-roles-bot.overlay
        prayer-times-applet.overlay
        hyprland-contrib.overlays.default
        rust-overlay.overlays.default
        # helix.overlays.default
        prismlauncher.overlays.default
        eza-overlay
        obs-text-pango-overlay
        # (import ./overlays/mpvpaper.nix)
        (import ./overlays/distrobox.nix)
        tokyonight-gtk-overlay
        evremap-overlay
        webcord-overlay
        # proxmox-nixos.overlays.${system}
      ];
    };

    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      pc = lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {
          inherit sadmadbotlad;
          inherit hyprland;
        };

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
          nixos-cosmic.nixosModules.default
        ];
      };
      laptop = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/laptop/configuration.nix

          nixos-cosmic.nixosModules.default
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
      alshaikh = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/alshaikh/configuration.nix

          nixos-cosmic.nixosModules.default
          nixos-hardware.nixosModules.framework-13-7040-amd
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.salman = {
              imports = [
                ./hosts/alshaikh/home.nix
              ];
            };
            home-manager.extraSpecialArgs = {inherit helix;};
          }
        ];
      };
      home-server = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          # {
          #   nix.settings = {
          #     substituters = ["https://cache.saumon.network/proxmox-nixos"];
          #     trusted-public-keys = ["proxmox-nixos:nveXDuVVhFDRFx8Dn19f1WDEaNRJjPrF2CPD2D+m1ys="];
          #   };
          # }
          ./hosts/home-server/configuration.nix
          sops-nix.nixosModules.sops
          arion.nixosModules.arion
          # proxmox-nixos.nixosModules.proxmox-ve
        ];
      };
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
  };
}
