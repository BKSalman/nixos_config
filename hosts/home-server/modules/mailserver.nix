{config, ...}: let
  domain = "mail.bksalman.com";
  inherit (config.security.acme) certs;
in {
  services.stalwart-mail = {
    enable = true;
    settings = {
      certificate."cert" = {
        cert = "file://${certs.${domain}.directory}/fullchain.pem";
        private-key = "file://${certs.${domain}.directory}/key.pem";
      };
      server = {
        hostname = domain;
        tls = {
          certificate = "cert";
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
        };
      };
      session = {
        rcpt.directory = "internal";
        auth = {
          mechanisms = ["LOGIN"];
          directory = "internal";
        };
      };
      jmap.directory = "internal";
      queue.outbound.next-hop = ["local"];
      directory."internal" = {
        type = "internal";
        store = "rocksdb";
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
      # group = "nginx";
    };
  };
}
