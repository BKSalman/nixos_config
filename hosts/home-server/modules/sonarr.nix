{config, ...}: let
  domain = "sonarr.bksalman.com";
in {
  services.sonarr = {
    enable = true;
    openFirewall = true;
    group = "multimedia";
  };

  # TODO: move all multimedia stuff to a single module
  systemd.tmpfiles.rules = [
    "d /mnt/media 0770 - multimedia - -"
  ];

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8989";
      proxyWebsockets = true;
      recommendedProxySettings = true;
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
