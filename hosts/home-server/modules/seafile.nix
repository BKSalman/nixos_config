{
  config,
  lib,
  ...
}: let
  domain = "seafile.bksalman.com";
in {
  options = {
    seafile.enable = lib.mkEnableOption "Enable Seafile";
  };

  config = lib.mkIf config.seafile.enable {
    services.seafile = {
      enable = true;

      adminEmail = "salman.f.abuhaimed@gmail.com";
      initialAdminPassword = "123";

      ccnetSettings.General.SERVICE_URL = "https://${domain}";

      seafileSettings = {
        fileserver = {
          host = "unix:/run/seafile/server.sock";
        };
      };

      dataDir = "/mnt/seafile-data";
    };

    services.nginx.virtualHosts.${domain} = {
      forceSSL = true;
      enableACME = true;
      locations = {
        "/" = {
          proxyPass = "http://unix:/run/seahub/gunicorn.sock";
          extraConfig = ''
            proxy_set_header   Host $host;
            proxy_set_header   X-Real-IP $remote_addr;
            proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header   X-Forwarded-Host $server_name;
            proxy_read_timeout  1200s;
            client_max_body_size 0;
          '';
        };
        "/seafhttp" = {
          proxyPass = "http://unix:/run/seafile/server.sock";
          extraConfig = ''
            rewrite ^/seafhttp(.*)$ $1 break;
            client_max_body_size 0;
            proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_connect_timeout  36000s;
            proxy_read_timeout  36000s;
            proxy_send_timeout  36000s;
            send_timeout  36000s;
          '';
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
  };
}
