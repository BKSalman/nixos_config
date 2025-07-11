{
  config,
  pkgs,
  ...
}: let
  domain = "paperless.bksalman.com";
in {
  services = {
    postgresql = {
      enable = true;
      ensureDatabases = ["paperless"];
      ensureUsers = [
        {
          name = "paperless";
          ensureDBOwnership = true;
        }
      ];
    };

    # Office document support
    tika.enable = true;
    gotenberg = {
      enable = true;
      port = 3500;
    };

    paperless = {
      enable = true;
      consumptionDirIsPublic = true;
      settings = {
        PAPERLESS_DBHOST = "/run/postgresql";
        PAPERLESS_TIKA_ENABLED = true;
        PAPERLESS_TIKA_ENDPOINT = "http://localhost:${builtins.toString config.services.tika.port}";
        PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://localhost:${builtins.toString config.services.gotenberg.port}";
        PAPERLESS_OCR_LANGUAGE = "ara+eng";
        PAPERLESS_OCR_USER_ARGS = {
          optimize = 1;
          pdfa_image_compression = "lossless";
        };
        PAPERLESS_URL = "https://${domain}";
        PAPERLESS_CONSUMER_IGNORE_PATTERN = [
          ".DS_STORE/*"
          "desktop.ini"
        ];
      };
    };
  };

  services.nginx = {
    enable = true;
    clientMaxBodySize = "50000m";
    virtualHosts.${domain} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.paperless.port}";
        # proxyWebsockets = true;
        recommendedProxySettings = true;
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
