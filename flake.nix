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
      url = "github:helix-editor/helix/24.07";
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

    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    };

    # TODO: remove when upstreamed to nixpkgs
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic/c294772655f83716e69f5585cb8b3aec049998a6";
    };

    # proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
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

    cloudflare-ddns-overlay = final: prev: {
      cloudflare-ddns = prev.callPackage ./packages/cloudflare-ddns {};
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
        ];
      };
      overlays = [
        # FIXME: remove after it gets fixed
        # nerdfonts-overlay

        cloudflare-ddns-overlay
        manmap.overlay
        leftwm.overlays.default
        ytdlp-gui.overlay
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

          {
            nix.settings = {
              substituters = ["https://cosmic.cachix.org/"];
              trusted-public-keys = ["cosmic.cachix.org-1:dya9iyxd4xdbehwjrkpv6rtxpmmdrel02smyza85dpe="];
            };
          }

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

          {
            nix.settings = {
              substituters = ["https://cosmic.cachix.org/"];
              trusted-public-keys = ["cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="];
            };
          }
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

          {
            nix.settings = {
              substituters = ["https://cosmic.cachix.org"];
              trusted-public-keys = ["cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="];
            };
          }
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
