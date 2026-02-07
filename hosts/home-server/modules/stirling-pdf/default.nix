{config, ...}: let
  domain = "stirling-pdf.bksalman.com";
  port = 3232;
in {
  services.stirling-pdf = {
    enable = true;
    environment = {
      INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "true";
      SERVER_PORT = port;
    };
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
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
