# reference: https://github.com/TechsupportOnHold/uxplay
{
  config,
  pkgs,
  lib,
  ...
}: {
  options = {
    uxplay.enable = lib.mkEnableOption "enable uxplay";
  };

  config = lib.mkIf config.uxplay.enable {
    # Open network ports
    networking.firewall.allowedTCPPorts = [7000 7001 7100];
    networking.firewall.allowedUDPPorts = [5353 6000 6001 7011];

    # To enable network-discovery
    services.avahi = {
      enable = true;
      nssmdns4 = true; # printing
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
        userServices = true;
        domain = true;
      };
    };
  };
}
