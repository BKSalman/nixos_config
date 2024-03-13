# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # ../x11
    # ../x11/bunnuafeth
    # ../x11/leftwm
    ../x11/awesome
    ../wayland
    ../wayland/buddaraysh
    ../uxplay.nix
    ../vm.nix
    # ../battery.nix
  ];

  nix = {
    package = pkgs.nixFlakes;
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

  programs.buddaraysh.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [pkgs.hplipWithPlugin pkgs.hplip];
  # services.avahi.enable = true;
  # services.avahi.nssmdns = true;
  # # for a WiFi printer
  # services.avahi.openFirewall = true;

  services.blueman.enable = true;

  hardware.bluetooth.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
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
  services.xserver.libinput.enable = true;
  services.xserver.libinput.touchpad.naturalScrolling = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.salman = {
    isNormalUser = true;
    description = "Salman";
    extraGroups = ["networkmanager" "wheel" "kvm" "docker" "podman" "sddm" "input" "audio" "video" "acme" "headscale"];
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
    rustup
    gcc

    probe-rs

    # IOS
    libimobiledevice
    ifuse

    firefox
    distrobox
    (cinnamon.nemo-with-extensions.override {
      extensions = [
        cinnamon.nemo-python
        cinnamon.nemo-fileroller
        (pkgs.callPackage ../packages/syncstate {})
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
    noto-fonts-cjk
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
    QT_QPA_PLATFORMTHEME = "kde";
    FLAKE = "/home/salman/nixos_config";
  };

  environment.noXlibs = false;

  environment.etc."makepkg.conf".source = "${pkgs.pacman}/etc/makepkg.conf";

  hardware = {
    opengl = {
      enable = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
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

  services.teamviewer.enable = true;

  # Fingerprint support
  # still not working tho
  services.fprintd = {
    enable = true;

    tod.enable = true;

    tod.driver = pkgs.libfprint-2-tod1-goodix;
  };

  # give acess to backlight to be able to change it from polybar or whatever
  services.udev.extraRules = builtins.concatStringsSep "\n" ((map (name: builtins.readFile (../udev-rules + ("/" + name))) (builtins.attrNames (builtins.readDir ../udev-rules)))
    ++ [
      "ACTION==\"add\", SUBSYSTEM==\"backlight\", KERNEL==\"amdgpu_bl0\", MODE=\"0666\", RUN+=\"${pkgs.coreutils}/bin/chmod a+w /sys/class/backlight/%k/brightness\""
    ]);
  # services.udev.extraRules = ''
  #
  # '';

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
