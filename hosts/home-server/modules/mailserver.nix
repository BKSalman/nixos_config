{
  lib,
  config,
  ...
}: let
  domain = "mail.bksalman.com";
  inherit (config.security.acme) certs;
in {
  services.stalwart-mail = {
    enable = true;
    settings = {
      server = {
        hostname = domain;
        tls = {
          certificate = "default";
          enable = true;
          implicit = false;
        };
        listener = {
          "smtp-submission" = {
            bind = ["[::]:587"];
            protocol = "smtp";
          };
          "imap" = {
            bind = ["[::]:143"];
            protocol = "imap";
          };
          "management" = {
            bind = ["127.0.0.1:8080"];
            protocol = "http";
          };
        };
      };
      session = {
        rcpt.directory = "'internal'";
        auth = {
          mechanisms = [
            {
              "if" = "local_port != 25 && is_tls";
              "then" = "[plain, login]";
            }
            {"else" = false;}
          ];
          directory = "'internal'";
        };
      };
      store = {
        db.type = "rocksdb";
        db.path = "/var/lib/stalwart-mail/db";
        db.compression = "lz4";
      };
      storage.blob = "db";
      jmap.directory = "internal";
      directory.internal.type = "internal";
      directory.internal.store = "db";
      certificate."default" = {
        cert = "%{file:${certs.${domain}.directory}/cert.pem}%";
        private-key = "%{file:${certs.${domain}.directory}/key.pem}%";
      };
      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:${config.sops.secrets.stalwart-salman-secret.path}}%";
      };
    };
  };
  users.users.stalwart-mail.extraGroups = [config.security.acme.certs.${domain}.group];

  networking.firewall = {
    allowedTCPPorts = [8080 25 587 465 143 993 4190 110 995];
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
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
