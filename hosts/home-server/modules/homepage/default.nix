{config, ...}: let
  domain = "home.bksalman.com";
in {
  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    services = [
      {
        "Cloud apps" = [
          {
            "immich" = {
              href = "https://immich.bksalman.com";
              description = "Immich server";
            };
          }
          {
            "nextcloud" = {
              href = "https://nextcloud.bksalman.com";
              description = "Nextcloud server";
            };
          }
        ];
      }
    ];
    settings = {
      title = "Dashboard";
      background = "https://nextcloud.bksalman.com/apps/files_sharing/publicpreview/AieSr6bj9SQfr28?x=1920&y=1080";
      layout = {
        "Cloud apps" = {
          style = "row";
          columns = 2;
        };
      };
    };
  };
  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString config.services.homepage-dashboard.listenPort}";
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
