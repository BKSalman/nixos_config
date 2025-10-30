{
  config,
  pkgs,
  ...
}: let
  fhs = let
    base = pkgs.appimageTools.defaultFhsEnvArgs;
  in
    pkgs.buildFHSEnv (base
      // {
        name = "fhs";
        targetPkgs = pkgs:
        # pkgs.buildFHSUserEnv provides only a minimal FHS environment,
        # lacking many basic packages needed by most software.
        # Therefore, we need to add them manually.
        #
        # pkgs.appimageTools provides basic packages required by most software.
          (base.targetPkgs pkgs)
          ++ (
            with pkgs; [
              pkg-config
              ncurses
              # Feel free to add more packages here if needed.
            ]
          );
        profile = "export FHS=1";
        runScript = "bash";
        extraOutputsToInstall = ["dev"];
      });
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./framework.nix
    ../../modules
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  programs.k3b.enable = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  jay.enable = true;

  niri.enable = false;

  cosmic.enable = false;

  # Enable networking
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
  };

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  # Set your time zone.
  time.timeZone = "Asia/Riyadh";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ar_SA.UTF-8";
    LC_IDENTIFICATION = "ar_SA.UTF-8";
    LC_MEASUREMENT = "ar_SA.UTF-8";
    LC_MONETARY = "ar_SA.UTF-8";
    LC_NAME = "ar_SA.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "ar_SA.UTF-8";
    LC_TELEPHONE = "ar_SA.UTF-8";
    LC_TIME = "ar_SA.UTF-8";
  };

  i18n.extraLocales = "all";

  fonts.packages = with pkgs; [
    liberation_ttf
    nerd-fonts.fira-code
    nerd-fonts.noto
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    corefonts
    # fira-code
    # fira-code-symbols
    mplus-outline-fonts.githubRelease
    # dina-font
    # proggyfonts
  ];

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # services.desktopManager.cosmic.enable = true;
  # services.displayManager.cosmic-greeter.enable = true;

  wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;

  environment.localBinInPath = true;

  # Configure keymap in X11
  services.xserver = {
    xkb = {
      layout = "us,ara";
      variant = "";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.salman = {
    isNormalUser = true;
    description = "salman";
    extraGroups = ["networkmanager" "wheel" "input" "docker" "cdrom"];
    packages = with pkgs; [
      kdePackages.kate
      #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

  #     CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
  #     CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

  #     CPU_MIN_PERF_ON_AC = 0;
  #     CPU_MAX_PERF_ON_AC = 100;
  #     CPU_MIN_PERF_ON_BAT = 0;
  #     CPU_MAX_PERF_ON_BAT = 20;

  #     # Optional helps save long term battery health
  #     START_CHARGE_THRESH_BAT0 = 40; # 40 and below it starts to charge
  #     STOP_CHARGE_THRESH_BAT0 = 80; # 80 and above it stops charging

  #     PCIE_ASPM_ON_BAT = "powersupersave";
  #   };
  # };
  # services.power-profiles-daemon.enable = false;
  # services.auto-cpufreq = {
  #   enable = true;
  #   settings = {
  #     # https://github.com/AdnanHodzic/auto-cpufreq
  #     battery = {
  #       governor = "powersave";
  #       turbo = "never";
  #     };
  #     charger = {
  #       governor = "performance";
  #       turbo = "auto";
  #     };
  #   };
  # };
  # powerManagement.powertop.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    iotop
    kdePackages.partitionmanager
    nixd
    ethersync
    distrobox
    unzip
    deno
    typst
    inotify-tools
    lsof
    fhs
    asciinema
    dig
    mission-center
    anki
    jujutsu
    mpvpaper
    blender
    pciutils
    usbutils
    xivlauncher
    mangohud
    sendme
    tree
    sops
    rpcs3
    dolphin-emu
    vesktop
    gcc
    rustup
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    easyeffects
    podman-compose
    acpica-tools
    edid-decode
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Open ports in the firewall.
  networking.firewall = {
    # enable = false;
    allowedTCPPorts = [3030 53317 3389];
    checkReversePath = "loose";
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [config.services.tailscale.port 53317 3389];
  };

  services.resolved.enable = true;

  environment.etc."makepkg.conf".source = "${pkgs.pacman}/etc/makepkg.conf";

  # Steam
  hardware.steam-hardware.enable = true;
  programs.steam.enable = true;
  programs.steam.remotePlay.openFirewall = true;

  services.flatpak.enable = true;

  virtualisation = {
    # Podman
    oci-containers.backend = "podman";
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      dockerSocket.enable = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };

    # Docker
    # oci-containers.backend = "docker";
    # docker = {
    #   enable = true;
    #   rootless = {
    #     enable = true;
    #     setSocketVariable = true;
    #   };
    # };
  };

  uxplay.enable = true;

  vm.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  hardware.keyboard.zsa.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Add any missing dynamic libraries for unpackaged programs
      # here, NOT in environment.systemPackages
      pkg-config
      openssl
      stdenv.cc.cc
    ];
  };
}
