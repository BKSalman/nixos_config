{
  pkgs,
  config,
  ...
}: let
  domain = "prometheus.bksalman.com";
in {
  services.prometheus = {
    enable = true;
    exporters = {
      zfs = {
        enable = true;
      };
      node = {
        enable = true;
        enabledCollectors = ["systemd"];
        port = 9091;
      };
    };

    scrapeConfigs = [
      {
        job_name = "prometheus-node";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }
      {
        job_name = "prometheus-zfs";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.prometheus.exporters.zfs.port}"];
          }
        ];
      }
    ];
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
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
