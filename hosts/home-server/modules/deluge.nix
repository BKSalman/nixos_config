{config, ...}: let
  domain = "deluge.bksalman.com";
in {
  services.deluge = {
    enable = true;
    web.enable = true;
    group = "multimedia";
    dataDir = "/mnt/media/torrent";
    declarative = true;
    config = {
      enabled_plugins = ["Label"];
      outgoing_interface = "wg1";
    };
    authFile = config.sops.secrets.deluge-web-auth.path;
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.deluge.web.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        proxy_set_header X-Deluge-Base "/";
        add_header X-Frame-Options SAMEORIGIN;
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [config.services.deluge.web.port];

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
