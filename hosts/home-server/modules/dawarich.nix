{
  config,
  lib,
  ...
}: {
  options = {
    dawarich.enable = lib.mkEnableOption "enable dawarich";
  };

  config = lib.mkIf config.dawarich.enable {
    services.dawarich = {
      enable = true;
      localDomain = "dawarich.bksalman.com";
      webPort = 4050;

      # pangolin/newt is the reverse proxy, dawarich serves its own
      # static assets from `public/`
      configureNginx = false;

      # local postgres (with postgis) and redis over a unix socket
      database.createLocally = true;
      redis.createLocally = true;
      automaticMigrations = true;

      # a dedicated process for reverse geocoding, so imports aren't
      # stuck behind the geocoding queue
      # https://dawarich.app/docs/FAQ/#how-to-speed-up-the-import-process
      sidekiqProcesses = {
        all = {
          jobClasses = [];
          threads = null;
        };
        geocoding = {
          jobClasses = ["reverse_geocoding"];
          threads = 10;
        };
      };

      environment = {
        # pangolin terminates TLS, so dawarich has to generate https URLs
        APPLICATION_PROTOCOL = "https";
        DISTANCE_UNIT = "km";
      };
    };
  };
}
