{
  pkgs,
  lib,
  config,
  proxmox-nixos,
  ...
}: {
  services.proxmox-ve = {
    enable = true;
    ipAddress = "192.168.0.225";
    bridges = ["vmbr0"];
  };

  networking = {
    bridges = {
      vmbr0 = {
        interfaces = ["enp7s0"];
      };
    };

    interfaces = {
      vmbr0 = {
        ipv4.addresses = [
          {
            address = "192.168.0.225";
            prefixLength = 24;
          }
        ];
      };
      enp7s0 = {
        useDHCP = false;
      };
    };

    defaultGateway = "192.168.0.1";
    nameservers = ["8.8.8.8" "1.1.1.1"];
  };

  environment.systemPackages = with pkgs; [
    novnc
  ];

  nixpkgs.overlays = [
    proxmox-nixos.overlays.${config.nixpkgs.hostPlatform.system}
  ];
}
