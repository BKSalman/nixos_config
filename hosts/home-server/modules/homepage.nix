{config, ...}: {
  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    services = [
      {
        "Cloud apps" = [
          {
            "immich" = {
              href = "immich.bksalman.com";
              description = "Immich server";
            };
          }
          {
            "nextcloud" = {
              href = "nextcloud.bksalman.com";
              description = "Nextcloud server";
            };
          }
        ];
      }
    ];
  };
  services.nginx.virtualHosts = {
    "home.bksalman.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString config.services.homepage-dashboard.listenPort}";
      };
    };
  };
}
