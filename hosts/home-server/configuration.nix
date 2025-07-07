{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./modules
    ./containers
    ../../modules/nix.nix
    ../../modules/ssh.nix
  ];

  boot = {
    loader = {
      grub.enable = false;
      systemd-boot = {
        enable = true;

        extraInstallCommands = ''
          ${pkgs.util-linux}/bin/mount -t vfat -o iocharset=iso8859-1 /dev/disk/by-label/boot /efiboot/efi
          ${pkgs.coreutils}/bin/cp -r /efiboot/efi/*
        '';
      };

      # generationsDir.copyKernels = true;

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/efiboot/efi";
      };
    };

    kernelPackages = pkgs.linuxPackages_6_12;

    initrd = {
      kernelModules = ["zfs"];

      # postDeviceCommands = ''
      #   zpool import -lf root
      # '';
    };

    supportedFilesystems = ["zfs"];

    zfs = {
      devNodes = "/dev/disk/by-partlabel";
      # https://search.nixos.org/options?channel=unstable&show=boot.zfs.forceImportRoot
      forceImportRoot = false;
    };
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.graphics = {
    enable = true;
    # driSupport = true;
    # driSupport32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      (pkgs.vaapiIntel.override {enableHybridCodec = true;})
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
    ];
  };

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  networking = {
    hostName = "nixos-server";
    defaultGateway = "192.168.0.1";
    nameservers = ["1.1.1.1"];
    interfaces.enp7s0.ipv4.addresses = [
      {
        address = "192.168.0.225";
        prefixLength = 24;
      }
    ];
    hostId = "f6c1cbac";
    firewall = {
      enable = true;
      allowedTCPPorts = [80 443 8080 111 2049 4000 4001 4002 20048 2283 25565];
      checkReversePath = "loose";
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [111 2049 4000 4001 4002 20048 config.services.tailscale.port 25565];
    };
    wireguard.enable = true;
    # Dummy routing table to stop wireguard from routing all traffic
    iproute2.enable = true;
    iproute2.rttablesExtraConfig = ''
      200 vpn
    '';
    wg-quick.interfaces.wg1 = {
      table = "vpn";
      address = ["10.70.98.176/32"];
      privateKeyFile = config.sops.secrets.wireguard-private-key.path;
      peers = [
        {
          publicKey = "VgNcwWy8MRhfEZY+XSisDM1ykX+uXlHQScOLqqGMLkc=";
          allowedIPs = ["0.0.0.0/0"];
          endpoint = "194.36.25.48:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = ["~."];
    fallbackDns = ["1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one"];
    dnsovertls = "true";
  };

  time.timeZone = "Asia/Riyadh";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.salman = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker" "multimedia"];
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJkV9LhQ+F3F9dWbpuqKQSkGaCSy9HWPmllFSYemLo5 pc"
    ];
  };

  users.groups.multimedia = {};

  environment.systemPackages = with pkgs; [
    dig
    lsof
    docker-compose
    sops
    git
    curl
    vim
    wget
  ];

  services.nfs.server = {
    enable = true;
    # fixed rpc.statd port; for firewall
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';
  };
  services.nfs.server.exports = ''
    /mnt/general         *(rw,fsid=0,no_subtree_check,no_root_squash)
  '';

  services.tailscale.enable = true;

  virtualisation.oci-containers.backend = "docker";
  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.docker = {
    enable = true;
  };

  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?
}
