{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./modules
    ../../modules
    ./nfs.nix
  ];

  leftwm.enable = false;

  # jay.enable = true;

  sway.enable = false;

  cosmic.enable = false;

  hyprland.enable = false;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/salman/nixos_config";
  };

  nextcloud.enable = false;

  # Enable virtual machines VFIO
  vfio.enable = true;

  # Enable android stuff
  programs.adb.enable = true;

  # udev rules
  services.udev.packages = [
    pkgs.android-udev-rules
  ];

  # boot.zfs.package = pkgs.linuxKernel.packages.linux_6_11.zfs_unstable;

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      {
        devices = ["nodev"];
        path = "/boot";
      }
    ];
  };
  services.zfs.autoScrub.enable = true;

  boot.loader.grub.useOSProber = true;
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1 v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
  '';
  # boot.binfmt.emulatedSystems = ["aarch64-linux"];

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

  wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    oxygen
  ];

  services.xserver = {
    enable = true;

    # displayManager.gdm.enable = true;
    # displayManager.gdm.wayland = true;
    # displayManager.sddm.enable = true;
    # displayManager.sddm.autoNumlock = true;

    xkb = {
      layout = "us,ara";
      options = "grp:alt_shift_toggle";
      variant = "";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.salman = {
    isNormalUser = true;
    description = "Salman";
    extraGroups = ["networkmanager" "wheel" "kvm" "docker" "podman" "sddm" "audio" "video" "adbusers"];
    packages = with pkgs; [
      kate
      #  thunderbird
    ];
  };

  programs.gamemode = {
    enable = true;
  };

  environment.localBinInPath = true;

  environment.systemPackages = with pkgs; [
    rustup
    # looking-glass-client
    prayer-times-applet
    easyeffects
    waydroid
    vesktop
    lutris
    heroic
    # winetricks
    # wineWowPackages.stable
    wineWowPackages.waylandFull
    zathura
    # mypaint
    # easyeffects
    sendme
    yazi
    ripgrep
    mangohud
    dig
    sops

    # mergerfs
    fzf
    tree
    # perl

    # IOS
    libimobiledevice
    ifuse

    zellij

    xdg-utils
    solaar
    (nemo-with-extensions.override {
      extensions = [
        nemo-python
        nemo-fileroller
        (pkgs.callPackage ../../packages/syncstate {})
      ];
    })
    # nextcloud-client
    gparted
    # docker-compose
    # podman-compose
    bat
    # tmux
    egl-wayland
    pciutils
    pkg-config
    alsa-lib
    # systemd
    libiconv
    cloudflared
    mold
    openssl
    dbus
    eggdbus
    # deja-dup
    # duplicity
    vim
    wget
    libsForQt5.ark
    libsecret
    nix-prefetch
  ];

  fonts.packages = with pkgs; [
    liberation_ttf
    nerd-fonts.fira-code
    nerd-fonts.noto
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    corefonts
    # fira-code
    # fira-code-symbols
    mplus-outline-fonts.githubRelease
    # dina-font
    # proggyfonts
  ];

  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
  };

  environment.sessionVariables = {
    # LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    # BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/${pkgs.lib.getVersion pkgs.clang}/include";
    # PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    WLR_NO_HARDWARE_CURSORS = "1";
    MANROFFOPT = "-c";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    EDITOR = "hx";
    QT_QPA_PLATFORMTHEME = "kde";
  };

  environment.etc."makepkg.conf".source = "${pkgs.pacman}/etc/makepkg.conf";

  # environment.etc."tmpfiles.d/10-looking-glass.conf" = {
  #   text = ''
  #     f	/dev/shm/looking-glass	0660	salman	kvm	-
  #   '';
  #   user = "salman";
  # };

  boot.kernelPackages = pkgs.linuxPackages_6_12;

  boot.extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];

  boot.kernelModules = [
    # Virtual Camera
    "v4l2loopback"
    # Virtual Microphone, built-in
    "snd-aloop"
  ];

  services.gvfs.enable = true;

  programs.dconf.enable = true;

  # services.duplicity.enable = true;
  # services.duplicity.frequency = null;
  # services.duplicity.targetUrl = "";

  programs.partition-manager.enable = true;

  services.ratbagd.enable = true;

  # xdg-desktop-portal works by exposing a series of D-Bus interfaces
  # known as portals under a well-known name
  # (org.freedesktop.portal.Desktop) and object path
  # (/org/freedesktop/portal/desktop).
  # The portal interfaces include APIs for file access, opening URIs,
  # printing and others.
  services.dbus.enable = true;

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  networking = {
    hostId = "97d1662c";
    hostName = "nixos";
    nameservers = ["1.1.1.1"];
    firewall.allowedTCPPorts = [5900 5800 5000 47989 47990 48010 47984 4000 8000 12345 443 80 3001 3030];
    firewall.allowedUDPPorts = [5900 5800 47989 47990 48010 47984 47999 4000 41641];
    networkmanager.enable = true;
    wireguard.enable = true;
  };

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = ["~."];
    fallbackDns = ["1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one"];
    dnsovertls = "true";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  systemd.services.cloudflared = {
    enable = true;
    wantedBy = ["multi-user.target"];
    requires = ["network-online.target"];
    after = ["network-online.target" "systemd-resolved.service"];
    serviceConfig = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run";
      Restart = "always";
      User = "salman";
    };
  };

  virtualisation = {
    oci-containers.backend = "docker";

    # Podman
    # podman = {
    #   enable = true;
    #   # Create a `docker` alias for podman, to use it as a drop-in replacement
    #   dockerCompat = true;
    #   dockerSocket.enable = true;
    #   # Required for containers under podman-compose to be able to talk to each other.
    #   defaultNetwork.settings.dns_enabled = true;
    # };

    # Docker
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };

  # Git
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
  };

  # Steam
  hardware.steam-hardware.enable = true;
  programs.steam.enable = true;
  programs.steam.remotePlay.openFirewall = true;

  services.mpd.enable = true;

  programs.xwayland.enable = true;

  hardware.opentabletdriver.enable = true;

  systemd.user.services.polkit-auth-agent = {
    enable = true;
    description = "polkit-kde-authentication-agent-1";
    wantedBy = ["graphical-session.target"];
    wants = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };

  services.gnome.gnome-keyring.enable = true;

  programs.kdeconnect.enable = true;

  # IOS
  services.usbmuxd = {
    enable = true;
    package = pkgs.usbmuxd2;
  };

  # temporary cus NetworkManager-wait-online fails the nixos switch
  systemd.services.NetworkManager-wait-online = {
    serviceConfig = {
      ExecStart = ["" "${pkgs.networkmanager}/bin/nm-online -q"];
      Restart = "on-failure";
      RestartSec = 1;
    };
    unitConfig.StartLimitIntervalSec = 0;
  };

  systemd.services.manmap = {
    enable = true;
    wantedBy = ["graphical-session.target"];
    serviceConfig = {
      ExecStart = "${pkgs.manmap}/bin/manmap -d \"Logitech G502\"";
      Restart = "always";
    };
  };

  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Add any missing dynamic libraries for unpackaged programs
      # here, NOT in environment.systemPackages
      gtk3
      pango
      harfbuzz
      libnotify
      xorg.libX11
      xorg.xrandr
      libxkbcommon
      atk
      cairo
      gdk-pixbuf
      glib
      xorg.libXScrnSaver
      xorg.libXtst
      xorg.libXext
      xorg.libXfixes
    ];
  };
}
