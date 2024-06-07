{
  config,
  pkgs,
  ...
}: {
  # FIXME: remove this and use nix-sops
  environment.etc."nextcloud-admin-pass" = {
    text = "PWD";
    user = "nextcloud";
    group = "nextcloud";
  };

  services.nextcloud = {
    enable = true;
    https = true;
    package = pkgs.nextcloud29;
    hostName = "nextcloud.bksalman.com";
    config.adminpassFile = "/etc/nextcloud-admin-pass";
    settings.trusted_domains = ["192.168.0.225"];
    configureRedis = true;
  };

  services.nginx = {
    enable = true;
    virtualHosts.${config.services.nextcloud.hostName} = {
      forceSSL = false;
    };
  };

  # security.acme = {
  #   acceptTerms = true;
  #   defaults.email = "salman.f.abuhaimed@gmail.com";
  #   certs.${config.services.nextcloud.hostName} = {
  #     dnsProvider = "cloudflare";
  #     # Supplying password files like this will make your credentials world-readable
  #     # in the Nix store. This is for demonstration purpose only, do not use this in production.
  #     environmentFile = "${pkgs.writeText "inwx-creds" ''
  #       INWX_USERNAME=xxxxxxxxxx
  #       INWX_PASSWORD=yyyyyyyyyy
  #     ''}";
  #   };
  # };
}
