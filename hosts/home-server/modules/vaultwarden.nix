{
  pkgs,
  config,
  ...
}: let
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

      # This example assumes a mailserver running on localhost,
      # thus without transport encryption.
      # If you use an external mail server, follow:
      #   https://github.com/dani-garcia/vaultwarden/wiki/SMTP-configuration
      SMTP_HOST = "127.0.0.1";
      SMTP_PORT = 25;
      SMTP_SECURITY = "force_tls";

      SMTP_USERNAME = "admin@$bitwarden.bksalman.com";
      # SMTP_PASSWORD = ""; # set in config.sops.secrets.vaultwarden-secrets

      SMTP_FROM = "admin@bitwarden.bksalman.com";
      SMTP_FROM_NAME = "example.com Bitwarden server";
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
