{
  config,
  lib,
  pkgs,
  ...
}: let
  domain = "seafile.bksalman.com";
  net = "seafile-net";
  envFile = config.sops.templates."seafile.env".path;
in {
  options = {
    seafile.enable = lib.mkEnableOption "Enable Seafile";
  };

  config = lib.mkIf config.seafile.enable {
    systemd.services.init-seafile-net = {
      description = "Create the ${net} docker network";
      wantedBy = ["multi-user.target"];
      after = ["docker.service"];
      before = ["docker-db.service" "docker-redis.service" "docker-seafile.service"];
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
      script = ''
        ${pkgs.docker}/bin/docker network inspect ${net} >/dev/null 2>&1 \
          || ${pkgs.docker}/bin/docker network create ${net}
      '';
    };

    virtualisation.oci-containers = {
      containers = {
        db = {
          image = "mariadb:10.11";
          # MYSQL_ROOT_PASSWORD comes from the secret env file below
          environment = {
            MYSQL_LOG_CONSOLE = "true";
            MARIADB_AUTO_UPGRADE = "1";
          };
          environmentFiles = [envFile];
          volumes = ["/mnt/seafile-mysql:/var/lib/mysql"];
          networks = [net];
        };

        redis = {
          image = "redis";
          # keeps the image's default entrypoint, overrides CMD like the compose did
          cmd = ["/bin/sh" "-c" "redis-server --requirepass \"$REDIS_PASSWORD\""];
          environmentFiles = [envFile];
          networks = [net];
        };

        seafile = {
          image = "seafileltd/seafile-pro-mc:13.0-latest";
          dependsOn = ["db" "redis"];
          # publish container :80 on the host so nginx can reach it
          ports = ["127.0.0.1:8882:8000"];
          volumes = ["/mnt/seafile-data:/shared"];
          environment = {
            SEAFILE_MYSQL_DB_HOST = "db";
            SEAFILE_MYSQL_DB_PORT = "3306";
            SEAFILE_MYSQL_DB_USER = "seafile";
            SEAFILE_MYSQL_DB_CCNET_DB_NAME = "ccnet_db";
            SEAFILE_MYSQL_DB_SEAFILE_DB_NAME = "seafile_db";
            SEAFILE_MYSQL_DB_SEAHUB_DB_NAME = "seahub_db";
            TIME_ZONE = "Etc/UTC"; # you're in Riyadh — maybe "Asia/Riyadh"
            INIT_SEAFILE_ADMIN_EMAIL = "salman.f.abuhaimed@gmail.com";
            SEAFILE_SERVER_HOSTNAME = domain;
            SEAFILE_SERVER_PROTOCOL = "https";
            SITE_ROOT = "/";
            NON_ROOT = "false";
            SEAFILE_LOG_TO_STDOUT = "false";
            ENABLE_GO_FILESERVER = "true";
            ENABLE_SEADOC = "true";
            SEADOC_SERVER_URL = "https://${domain}/sdoc-server";
            CACHE_PROVIDER = "redis";
            REDIS_HOST = "redis";
            REDIS_PORT = "6379";
            ENABLE_NOTIFICATION_SERVER = "false";
            ENABLE_SEAFILE_AI = "false";
            ENABLE_FACE_RECOGNITION = "false";
            MD_FILE_COUNT_LIMIT = "100000";
          };
          # secret env vars (root pw, db pw, admin pw, redis pw, JWT key) from env file
          environmentFiles = [envFile];
          networks = [net];
        };
      };
    };

    # Secrets rendered to /run (NOT into the world-readable nix store)
    sops.templates."seafile.env".content = ''
      MYSQL_ROOT_PASSWORD=${config.sops.placeholder."seafile/mysql-root-password"}
      INIT_SEAFILE_MYSQL_ROOT_PASSWORD=${config.sops.placeholder."seafile/mysql-root-password"}
      SEAFILE_MYSQL_DB_PASSWORD=${config.sops.placeholder."seafile/db-password"}
      INIT_SEAFILE_ADMIN_PASSWORD=${config.sops.placeholder."seafile/admin-password"}
      REDIS_PASSWORD=${config.sops.placeholder."seafile/redis-password"}
      JWT_PRIVATE_KEY=${config.sops.placeholder."seafile/jwt-key"}
    '';
    sops.secrets = {
      "seafile/mysql-root-password" = {};
      "seafile/db-password" = {};
      "seafile/admin-password" = {};
      "seafile/redis-password" = {};
      "seafile/jwt-key" = {}; # must be >= 32 chars
    };

    # services.nginx.virtualHosts.${domain} = {
    #   # forceSSL = true;
    #   # enableACME = true;

    #   # The container's internal proxy handles /seafhttp, /sdoc-server,
    #   # /notification etc. itself — so a single "/" proxy is all you need.
    #   locations."/" = {
    #     proxyPass = "http://127.0.0.1:8882";
    #     proxyWebsockets = true; # for SeaDoc / notification server
    #     extraConfig = ''
    #       proxy_set_header   Host $host;
    #       proxy_set_header   X-Real-IP $remote_addr;
    #       proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    #       proxy_set_header   X-Forwarded-Proto $scheme;
    #       proxy_set_header   X-Forwarded-Host $server_name;
    #       proxy_read_timeout  1200s;
    #       client_max_body_size 0;
    #     '';
    #   };
    # };

    # security.acme = {
    #   acceptTerms = true;
    #   defaults.email = "salman.f.abuhaimed@gmail.com";
    #   certs.${domain} = {
    #     dnsProvider = "cloudflare";
    #     environmentFile = config.sops.secrets.cloudflare-api-info.path;
    #     webroot = null;
    #     group = "nginx";
    #   };
    # };
  };
}
