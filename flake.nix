{
  description = "Salman's System Configuration :)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    nur = {
      url = "github:nix-community/NUR";
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
      url = "github:mattwparas/helix/steel-event-system";
    };

    ytdlp-gui = {
      url = "github:bksalman/ytdlp-gui";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # prayer-times-applet = {
    #   url = "github:bksalman/prayer-times-applet";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    leftwm = {
      url = "github:leftwm/leftwm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    manmap = {
      url = "github:bksalman/manmap";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sadmadbotlad = {
      url = "github:bksalman/sadmadbotlad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    reaction-roles-bot = {
      url = "github:bksalman/reaction_roles";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    proxmox-nixos = {
      url = "github:SaumonNet/proxmox-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    determinate,
    hyprland-contrib,
    prismlauncher,
    helix,
    ytdlp-gui,
    # prayer-times-applet,
    leftwm,
    manmap,
    sadmadbotlad,
    arion,
    sops-nix,
    nixos-hardware,
    nixos-cosmic,
    reaction-roles-bot,
    nur,
    proxmox-nixos,
    quickshell,
    ...
  }: let
    system = "x86_64-linux";

    tokyonight-gtk-overlay = final: prev: {
      tokyonight-gtk = prev.callPackage ./packages/tokyonight {};
    };

    evremap-overlay = final: prev: {
      evremap = prev.callPackage ./packages/evremap {};
    };

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          # "python-2.7.18.8"
          # "python-2.7.18.6"
          "qtwebengine-5.15.19"

          # FIXME: remove after https://github.com/NixOS/nixpkgs/issues/360592
          # and https://github.com/NixOS/nixpkgs/issues/326335 are sorted out
          # "aspnetcore-runtime-6.0.36"
          # "aspnetcore-runtime-wrapped-6.0.36"
          # "dotnet-sdk-6.0.428"
          # "dotnet-sdk-wrapped-6.0.428"
        ];
      };
      overlays = [
        manmap.overlay
        leftwm.overlays.default
        ytdlp-gui.overlay
        reaction-roles-bot.overlay
        # prayer-times-applet.overlay
        hyprland-contrib.overlays.default
        # helix.overlays.default
        prismlauncher.overlays.default
        # (import ./overlays/mpvpaper.nix)
        tokyonight-gtk-overlay
        evremap-overlay
        # proxmox-nixos.overlays.${system}
        nur.overlays.default
      ];
    };

    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      pc = lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {
          inherit sadmadbotlad;
          inherit nixos-cosmic;
        };

        modules = [
          determinate.nixosModules.default

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
            home-manager.extraSpecialArgs = {
              inherit helix;
              inherit sadmadbotlad;
              inherit quickshell;
            };
          }

          ./hosts/pc/configuration.nix
        ];
      };
      laptop = lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./hosts/laptop/configuration.nix

          determinate.nixosModules.default

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.salman = {
              imports = [
                ./hosts/laptop/home.nix
              ];
            };
            home-manager.extraSpecialArgs = {
              inherit helix;
            };
          }
        ];
      };
      alshaikh = lib.nixosSystem {
        specialArgs = {
          inherit nixos-cosmic;
        };
        inherit system pkgs;

        modules = [
          ./hosts/alshaikh/configuration.nix

          nixos-hardware.nixosModules.framework-13-7040-amd

          determinate.nixosModules.default

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.salman = {
              imports = [
                ./hosts/alshaikh/home.nix
              ];
            };
            home-manager.extraSpecialArgs = {
              inherit helix;
              inherit quickshell;
            };
          }
        ];
      };
      home-server = lib.nixosSystem {
        inherit system pkgs;
        specialArgs = {
          inherit proxmox-nixos;
        };

        modules = [
          ./hosts/home-server/configuration.nix
          sops-nix.nixosModules.sops
          arion.nixosModules.arion
          proxmox-nixos.nixosModules.proxmox-ve
        ];
      };
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
  };
}
