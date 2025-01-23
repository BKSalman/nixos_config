{config, ...}: let
  domain = "bitwarden.bksalman.com";
in {
  services.vaultwarden = {
    enable = true;
    # dbBackend = "mysql";
    backupDir = "/var/backup/vaultwarden";
    environmentFile = config.sops.secrets.vaultwarden-secrets.path;
    config = {
      DOMAIN = "https://${domain}";
      SIGNUPS_ALLOWED = false;

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;

      ROCKET_LOG = "critical";

      SMTP_FROM_NAME = "bksalman.com Bitwarden server";
      # Other SMTP settings are in the vaultwarden secrets
    };
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
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
