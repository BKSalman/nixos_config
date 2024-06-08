{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./modules/nextcloud.nix
    ./modules/sops.nix
    ./modules/immich.nix
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

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

      generationsDir.copyKernels = true;

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/efiboot/efi";
      };
    };

    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    initrd = {
      kernelModules = ["zfs"];

      postDeviceCommands = ''
        zpool import -lf root
      ''; # postDeviceCommands
    }; # initrd

    supportedFilesystems = ["zfs"];

    zfs = {
      devNodes = "/dev/disk/by-partlabel";
    };
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
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
  };

  time.timeZone = "Asia/Riyadh";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.salman = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker"];
    packages = with pkgs; [];
  };

  environment.systemPackages = with pkgs; [
    docker-compose
    sops
    git
    curl
    vim
    wget
  ];

  services.openssh = {
    enable = true;
    ports = [222];
    openFirewall = true;
  };

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

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443 8080 111 2049 4000 4001 4002 20048 2283];
    checkReversePath = "loose";
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [111 2049 4000 4001 4002 20048 config.services.tailscale.port];
  };

  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
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
