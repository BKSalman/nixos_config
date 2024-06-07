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

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443 8080 111 2049 4000 4001 4002 20048];
    allowedUDPPorts = [111 2049 4000 4001 4002 20048];
  };

  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker.enable = true;

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/salman/.config/sops/age/keys.txt";
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
