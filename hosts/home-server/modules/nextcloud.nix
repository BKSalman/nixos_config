{
  config,
  pkgs,
  ...
}: {
  services.nextcloud = {
    enable = true;
    https = true;
    package = pkgs.nextcloud29;
    hostName = "nextcloud.bksalman.com";
    config.adminpassFile = config.sops.secrets.nextcloud-admin-pass.path;
    settings.trusted_domains = ["192.168.0.225"];
    configureRedis = true;
    datadir = "/mnt/ncdata";
  };

  services.nginx = {
    enable = true;
    virtualHosts.${config.services.nextcloud.hostName} = {
      forceSSL = true;
      enableACME = true;
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "salman.f.abuhaimed@gmail.com";
    certs.${config.services.nextcloud.hostName} = {
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets.cloudflare-api-info.path;
      webroot = null;
      group = "nginx";
    };
  };
}
