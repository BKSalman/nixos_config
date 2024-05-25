# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  sadmadbotlad,
  ...
}: let
  jay-wrapped = pkgs.writeText "jay-wrapped" ''
    #!/usr/bin/env bash

    export XDG_SESSION_TYPE=wayland
    export XDG_SESSION_DESKTOP=jay
    export XDG_CURRENT_DESKTOP=jay

    export CLUTTER_BACKEND=wayland
    export ECORE_EVAS_ENGINE=wayland
    export ELM_ENGINE=wayland
    export SDL_VIDEODRIVER=wayland
    export _JAVA_AWT_WM_NONREPARENTING=1
    export NO_AT_BRIDGE=1

    ${pkgs.jay}/bin/jay --log-level info run
  '';
  jay-with-session = pkgs.jay.overrideAttrs (final: prev: let
    session = pkgs.writeText "jay" ''
      [Desktop Entry]
      Name=Jay
      Exec=${pkgs.jay}/bin/jay --log-level info run
      Type=Application
    '';
  in {
    postInstall =
      prev.postInstall
      + ''
        install -D ${session} $out/share/wayland-sessions/jay.desktop
      '';
    passthru.providedSessions = ["jay"];
  });
in {
  imports = [
    # Include the results of the hardware scan.
    # ../sunshine/services.sunshine.nix
    ./hardware-configuration.nix
    # ../wayland
    ./modules
    ../../modules
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Enable leftwm
  leftwm.enable = true;

  services.displayManager.defaultSession = "jay";

  # Enable nextcloud
  nextcloud.enable = false;

  # Enable virtual machines VFIO
  vfio.enable = true;

  # enable android stuff
  programs.adb.enable = true;

  # udev rules
  services.udev.packages = [
    pkgs.android-udev-rules
  ];

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

  networking.hostId = "97d1662c";

  boot.loader.grub.useOSProber = true;
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1 v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
  '';
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # networking.hosts = {
  #   "127.0.0.1:3030" = ["test.wow.com"];
  # };

  # Enable networking
  networking.networkmanager.enable = true;

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

  services.displayManager.sessionPackages = [
    jay-with-session
    pkgs.hyprland
  ];

  services.xserver = {
    enable = true;

    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    # displayManager.sddm.enable = true;
    # displayManager.sddm.autoNumlock = true;
    # desktopManager.plasma5.enable = true;

    videoDrivers = ["nvidia"];

    xkb = {
      layout = "us,ara";
      options = "grp:alt_shift_toggle";
      variant = "";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

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
  # services.xserver.libinput.enable = true;

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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # mergerfs
    fzf
    tree

    jay-with-session
    # perl
    # IOS
    libimobiledevice
    ifuse

    zellij

    xdg-utils
    solaar
    (cinnamon.nemo-with-extensions.override {
      extensions = [
        cinnamon.nemo-python
        cinnamon.nemo-fileroller
        (pkgs.callPackage ../../packages/syncstate {})
      ];
    })
    # nextcloud-client
    gparted
    # nixops_unstable
    # docker-compose
    # podman-compose
    bat
    # tmux
    egl-wayland
    firefox-wayland
    pciutils
    pkg-config
    alsa-lib
    # systemd
    libiconv
    cloudflared
    mold
    openssl
    clang
    dbus
    eggdbus
    deja-dup
    duplicity
    vim
    wget
    libsForQt5.ark
    libsecret
    nix-prefetch
  ];

  fonts.packages = with pkgs; [
    liberation_ttf
    nerdfonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    corefonts
    # fira-code
    # fira-code-symbols
    mplus-outline-fonts.githubRelease
    # dina-font
    # proggyfonts
  ];

  services.flatpak.enable = true;

  environment.sessionVariables = {
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/${pkgs.lib.getVersion pkgs.clang}/include";
    # PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    WLR_NO_HARDWARE_CURSORS = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    MANROFFOPT = "-c";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    QT_QPA_PLATFORMTHEME = "kde";
  };

  environment.etc."makepkg.conf".source = "${pkgs.pacman}/etc/makepkg.conf";

  environment.etc."tmpfiles.d/10-looking-glass.conf" = {
    text = ''
      f	/dev/shm/looking-glass	0660	salman	kvm	-
    '';
    user = "salman";
  };

  # Nvidia stuff

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
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      powerManagement.enable = true;
    };
  };

  # for ZFS compatibility
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  boot.kernelModules = [
    # Virtual Camera
    "v4l2loopback"
    # Virtual Microphone, built-in
    "snd-aloop"
  ];

  services.gvfs.enable = true;

  programs.dconf.enable = true;

  services.duplicity.enable = true;
  services.duplicity.frequency = null;
  services.duplicity.targetUrl = "";

  programs.partition-manager.enable = true;

  services.ratbagd.enable = true;

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

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [25565 22 5900 5800 5000 47989 47990 48010 47984 4000 8000 12345 443 80 3001 3030];
  networking.firewall.allowedUDPPorts = [25565 5900 5800 47989 47990 48010 47984 47999 4000 41641];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

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

  # programs.hyprland.enable = true;

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
    "text/html" = "librewolf.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
  };

  # TODO: figure out if this could be done without changing nix store path
  # merge /nix/store with other drive for extra disk space
  # fileSystems."/nix/store" = {
  #   fsType = "fuse.mergerfs";
  #   device = "/media/extra/nix-store:/nix/store";
  #   options = ["cache.files=partial" "dropcacheonclose=true" "category.create=mfs"];
  # };
}
