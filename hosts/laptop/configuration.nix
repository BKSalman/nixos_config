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

  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1 v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
  '';

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

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
    # desktopManager.plasma5.enable = true;
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

  hardware.pulseaudio.enable = false;
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
  services.libinput.touchpad.naturalScrolling = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.salman = {
    isNormalUser = true;
    description = "Salman";
    extraGroups = ["networkmanager" "wheel" "kvm" "docker" "podman" "sddm" "input" "audio" "video" "acme" "headscale" "plugdev"];
    packages = with pkgs; [
      kate
      #  thunderbird
    ];
  };

  # # Allow unfree packages
  # config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    sops
    zathura

    rustup
    gcc

    probe-rs

    # IOS
    libimobiledevice
    ifuse

    firefox
    distrobox
    (nemo-with-extensions.override {
      extensions = [
        nemo-python
        nemo-fileroller
        (pkgs.callPackage ../../packages/syncstate {})
      ];
    })
    pciutils
    pkg-config
    alsa-lib
    systemd
    libiconv
    openssl
    dbus
    eggdbus
    deja-dup
    duplicity
    vim
    neovim
    helix
    wget
    libsForQt5.ark
    libsecret
    nix-prefetch
    gamemode
  ];

  fonts.packages = with pkgs; [
    liberation_ttf
    nerdfonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    corefonts
    google-fonts
    # fira-code
    # fira-code-symbols
    mplus-outline-fonts.githubRelease
    # dina-font
    # proggyfonts
  ];

  services.flatpak.enable = true;
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    MANROFFOPT = "-c";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    EDITOR = "hx";
  };

  environment.noXlibs = false;

  environment.etc."makepkg.conf".source = "${pkgs.pacman}/etc/makepkg.conf";

  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        vaapiVdpau
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

  services.ratbagd.enable = true;

  services.input-remapper.enable = true;

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

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.tailscale.enable = true;

  # Open ports in the firewall.
  networking.firewall = {
    # enable = false;
    allowedTCPPorts = [8101 8000 8080 443 11000 4000 53317];
    checkReversePath = "loose";
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [41641 config.services.tailscale.port];
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
  services.usbmuxd.enable = true;

  programs.droidcam.enable = true;

  # services.teamviewer.enable = true;

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

    ACTION!="add|change", GOTO="probe_rs_rules_end"

    SUBSYSTEM=="gpio", MODE="0660", GROUP="plugdev", TAG+="uaccess"

    SUBSYSTEM!="usb|tty|hidraw", GOTO="probe_rs_rules_end"

    # Please keep this list sorted by VID:PID

    # STMicroelectronics ST-LINK V1
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3744", MODE="660", GROUP="plugdev", TAG+="uaccess"

    # STMicroelectronics ST-LINK/V2
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", MODE="660", GROUP="plugdev", TAG+="uaccess"

    # STMicroelectronics ST-LINK/V2.1
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374b", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3752", MODE="660", GROUP="plugdev", TAG+="uaccess"

    # STMicroelectronics STLINK-V3
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374d", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374e", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374f", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3753", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3754", MODE="660", GROUP="plugdev", TAG+="uaccess"

    # SEGGER J-Link
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0101", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0102", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0103", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0104", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0105", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0107", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0108", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1001", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1002", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1003", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1004", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1005", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1006", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1007", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1008", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1009", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="100a", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="100b", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="100c", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="100d", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="100e", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="100f", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1010", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1011", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1012", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1013", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1014", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1015", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1016", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1017", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1018", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1019", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="101a", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="101b", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="101c", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="101d", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="101e", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="101f", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1020", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1021", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1022", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1023", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1024", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1025", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1026", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1027", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1028", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1029", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="102a", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="102b", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="102c", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="102d", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="102e", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="102f", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1050", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1051", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1052", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1053", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1054", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1055", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1056", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1057", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1058", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1059", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="105a", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="105b", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="105c", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="105d", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="105e", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="105f", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1060", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1061", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1062", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1063", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1064", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1065", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1066", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1067", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1068", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1069", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="106a", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="106b", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="106c", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="106d", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="106e", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1366", ATTRS{idProduct}=="106f", MODE="660", GROUP="plugdev", TAG+="uaccess"

    # FT232H
    ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="660", GROUP="plugdev", TAG+="uaccess"
    # FT2232x
    ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="660", GROUP="plugdev", TAG+="uaccess"
    # FT4232H
    ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6011", MODE="660", GROUP="plugdev", TAG+="uaccess"

    # FTDI-based Olimex devices
    ATTRS{idVendor}=="0x15ba", ATTRS{idProduct}=="0x0003", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0x15ba", ATTRS{idProduct}=="0x0004", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0x15ba", ATTRS{idProduct}=="0x002a", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0x15ba", ATTRS{idProduct}=="0x002b", MODE="660", GROUP="plugdev", TAG+="uaccess"

    # Espressif USB JTAG/serial debug unit
    ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1001", MODE="660", GROUP="plugdev", TAG+="uaccess"
    # Espressif USB Bridge
    ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1002", MODE="660", GROUP="plugdev", TAG+="uaccess"

    # CMSIS-DAP compatible adapters
    ATTRS{product}=="*CMSIS-DAP*", MODE="660", GROUP="plugdev", TAG+="uaccess"
    # WCH Link (CMSIS-DAP compatible adapter)
    ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="8011", MODE="660", GROUP="plugdev", TAG+="uaccess"

    LABEL="probe_rs_rules_end"
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
}
