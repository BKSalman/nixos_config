{
  config,
  pkgs,
  lib,
  ...
}: {
  options = {
    nextcloud.enable = lib.mkEnableOption "Enable nextcloud";
  };

  config = lib.mkIf config.nextcloud.enable {
    services.nextcloud = {
      enable = true;
      https = true;
      package = pkgs.nextcloud29;
      hostName = "nextcloud.bksalman.com";
      database.createLocally = true;
      config = {
        adminpassFile = config.sops.secrets.nextcloud-admin-pass.path;
        dbtype = "pgsql";
      };
      settings.trusted_domains = ["192.168.0.225"];
      configureRedis = true;
      datadir = "/mnt/ncdata";
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "salman.f.abuhaimed@gmail.com";
      certs.${config.services.nextcloud.hostName} = {
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.cloudflare-api-info.path;
        webroot = null;
        group = "nginx";
      };
    };
  };
}
