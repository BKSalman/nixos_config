{
  config,
  pkgs,
  ...
}: let
  domain = "immich.bksalman.com";
in {
  services.immich = {
    enable = true;
    mediaLocation = "/mnt/immich/data";
  };

  # `null` will give access to all devices.
  services.immich.accelerationDevices = null;

  users.users.immich.extraGroups = ["video" "render"];

  services.nginx = {
    enable = true;
    clientMaxBodySize = "50000m";
    virtualHosts.${domain} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://[::1]:${toString config.services.immich.port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout   600s;
          proxy_send_timeout   600s;
          send_timeout         600s;
        '';
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "salman.f.abuhaimed@gmail.com";
    certs.${domain} = {
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets.cloudflare-api-info.path;
      webroot = null;
      group = "nginx";
    };
  };
}
