{config, ...}: let
  domain = "home.bksalman.com";
in {
  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    services = [
      {
        "Cloud storage" = [
          {
            "Immich" = {
              icon = "immich";
              href = "https://immich.bksalman.com";
              description = "Image backup";
            };
          }
          {
            "Nextcloud" = {
              icon = "nextcloud";
              href = "https://nextcloud.bksalman.com";
              description = "Cloud storage";
            };
          }
        ];
      }
      {
        "Media" = [
          {
            "Jellyfin" = {
              icon = "jellyfin";
              href = "https://jellyfin.bksalman.com";
              description = "Media manager";
            };
          }
          {
            "Sonarr" = {
              icon = "sonarr";
              href = "https://sonarr.bksalman.com";
              description = "Series management";
              widget = {
                type = "sonarr";
                url = "https://sonarr.bksalman.com";
                # exposing this doesn't matter since these services aren't exposed to the internet and run in a VPN
                key = "2af871145d664d40995984bca9945962";
              };
            };
          }
          {
            "Radarr" = {
              icon = "radarr";
              href = "https://radarr.bksalman.com";
              description = "Movie management";
              widget = {
                type = "radarr";
                url = "https://radarr.bksalman.com";
                # exposing this doesn't matter since these services aren't exposed to the internet and run in a VPN
                key = "7ca0de3ddd4349e59789864a5fc8b60c";
              };
            };
          }
          {
            "Prowlarr" = {
              icon = "prowlarr";
              href = "https://prowlarr.bksalman.com";
              description = "Prowlarr server";
              widget = {
                type = "prowlarr";
                url = "https://prowlarr.bksalman.com";
                # exposing this doesn't matter since these services aren't exposed to the internet and run in a VPN
                key = "bef8dba5f3d7444cb4ca51aa43a111d9";
              };
            };
          }
        ];
      }
      {
        "Administration" = [
          {
            "Grafana" = {
              icon = "grafana";
              href = "https://grafana.bksalman.com";
              description = "Monitor system";
            };
          }
          {
            "Prometheus" = {
              icon = "prometheus";
              href = "https://prometheus.bksalman.com";
            };
          }
        ];
      }
    ];
    settings = {
      title = "Dashboard";
      background = {
        # this doesn't accept absolute paths, so I can't give it a path from nix store :(
        image = "https://immich.bksalman.com/api/assets/2ba2efc3-df58-4fa1-8696-f23a3a3de328/thumbnail?size=preview&key=Qxo_Vu75DjG4biecQ2aCD_7lHn0vcIoKen4Nxq0om2pq4jVDnql6u0uWc0VigY7MVyg&c=JRZ9xms0YQ449fe4COqnZ05ZYao%3D";
        blur = "sm";
        saturate = "50";
        brightness = "50";
      };
      theme = "dark";
      color = "red";
      layout = {
        "Cloud storage" = {
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
