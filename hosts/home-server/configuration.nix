{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
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
      }; # systemd-boot

      generationsDir.copyKernels = true;

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/efiboot/efi";
      }; # efi
    }; # loader

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
    }; # zfs
  }; # boot

  networking.hostName = "nixos-server";
  networking.hostId = "f6c1cbac";
  time.timeZone = "Asia/Riyadh";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.salman = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    packages = with pkgs; [];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    curl
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
  ];

  services.openssh = {
    enable = true;
    ports = [222];
    openFirewall = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
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
