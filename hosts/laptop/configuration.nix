{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    # ../battery.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1 v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
  '';

  boot.kernelPackages = pkgs.linuxPackages_zen;

  wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sessionPackages = with pkgs; [
    kdePackages.plasma-bigscreen
  ];

  environment.localBinInPath = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.wifi.backend = "iwd";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  # networking.wireless.iwd.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Riyadh";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    # LC_ADDRESS = "en_US.UTF-8";
    # LC_IDENTIFICATION = "en_US.UTF-8";
    # LC_MEASUREMENT = "en_US.UTF-8";
    # LC_MONETARY = "en_US.UTF-8";
    # LC_NAME = "en_US.UTF-8";
    # LC_NUMERIC = "en_US.UTF-8";
    # LC_PAPER = "en_US.UTF-8";
    # LC_TELEPHONE = "en_US.UTF-8";
    # LC_TIME = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };

  services.xserver = {
    # displayManager.lightdm.enable = true;
    # displayManager.gdm.enable = true;
    # displayManager.gdm.wayland = true;
    # displayManager.defaultSession = "none+leftwm";
    # windowManager.bunnuafeth.enable = true;
    enable = true;
    xkb = {
      layout = "us,ara";
      options = "grp:alt_shift_toggle";
      variant = "";
    };
  };

  # TODO: maybe add this back later
  # programs.buddaraysh.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  # TODO: uncomment when sip becomes compatible with python 3.12
  # services.printing.drivers = [pkgs.hplipWithPlugin];
  # services.avahi.enable = true;
  # services.avahi.nssmdns = true;
  # # for a WiFi printer
  # services.avahi.openFirewall = true;

  services.blueman.enable = true;

  hardware.bluetooth.enable = true;

  # hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;
#   services.libinput.touchpad.naturalScrolling = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.salman = {
    isNormalUser = true;
    description = "Salman";
    extraGroups = ["networkmanager" "wheel" "kvm" "docker" "podman" "sddm" "input" "audio" "video" "acme" "headscale" "plugdev" "ydotool"];
    packages = with pkgs; [
      kdePackages.kate
      #  thunderbird
    ];
  };

  # # Allow unfree packages
  # config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    libva-utils
    fastfetch
    kdePackages.plasma-bigscreen
    sops

    # IOS
    libimobiledevice
    ifuse

    firefox
    distrobox
    pciutils
    vim
    neovim
    helix
    wget
  ];

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

  services.flatpak.enable = true;
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
    MANROFFOPT = "-c";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    EDITOR = "hx";
  };

  environment.etc."makepkg.conf".source = "${pkgs.pacman}/etc/makepkg.conf";

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;  # needed for Steam/some apps
      extraPackages = with pkgs; [
        mesa
        libva-utils
        libva-vdpau-driver
        libvdpau-va-gl
        pipewire
      ];
    };
  };

  boot.extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];

  boot.kernelModules = [
    # Virtual Camera
    "v4l2loopback"
    # Virtual Microphone, built-in
    "snd-aloop"
  ];

  # GNOME stuff

  services.gvfs.enable = true;

  programs.dconf.enable = true;

  services.duplicity.enable = true;
  services.duplicity.frequency = null;
  services.duplicity.targetUrl = "";

  # KDE stuff

  programs.partition-manager.enable = true;

  # services.ratbagd.enable = true;

  # xdg-desktop-portal works by exposing a series of D-Bus interfaces
  # known as portals under a well-known name
  # (org.freedesktop.portal.Desktop) and object path
  # (/org/freedesktop/portal/desktop).
  # The portal interfaces include APIs for file access, opening URIs,
  # printing and others.
  services.dbus.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  services.tailscale.enable = true;

  # Open ports in the firewall.
  networking.firewall = {
    # enable = false;
    allowedTCPPorts = [3389 101 8000 8080 443 11000 4000 53317];
    checkReversePath = "loose";
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [3389 41641 config.services.tailscale.port];
  };
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  # networking.nameservers = [ "100.100.100.100" "8.8.8.8" "1.1.1.1" ];
  # networking.search = [ "taildb9db.ts.net" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  # systemd.services.cloudflared = {
  #   enable = true;
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "network-online.target" "systemd-resolved.service" ];
  #   serviceConfig = {
  #     ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run";
  #     Restart = "always";
  #     User = "salman";
  #   };
  # };

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

  programs.nix-ld.enable = true;

  # Git
  programs.git = {
    enable = true;
    lfs.enable = true;
    package = pkgs.gitFull;
  };

  # Steam
  hardware.steam-hardware.enable = true;
  programs.steam.enable = true;
  programs.steam.remotePlay.openFirewall = true;

  services.mpd.enable = true;

  programs.xwayland.enable = true;

  # hardware.opentabletdriver.enable = true;

  services.gnome.gnome-keyring.enable = true;

  programs.kdeconnect.enable = true;

  # IOS
  services.usbmuxd.enable = true;

  # programs.droidcam.enable = true;

  # Fingerprint support
  # still not working tho
  services.fprintd = {
    enable = true;

    tod.enable = true;

    tod.driver = pkgs.libfprint-2-tod1-goodix;
  };

  # give acess to backlight to be able to change it from polybar or whatever
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl0", MODE="0666", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/class/backlight/%k/brightness"
  '';

  # temporary cus NetworkManager-wait-online fails the nixos switch
  systemd.services.NetworkManager-wait-online = {
    serviceConfig = {
      ExecStart = ["" "${pkgs.networkmanager}/bin/nm-online -q"];
      Restart = "on-failure";
      RestartSec = 1;
    };
    unitConfig.StartLimitIntervalSec = 0;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  services.fstrim.enable = true;

  programs.ydotool.enable = true;
}
