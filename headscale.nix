{ config, pkgs, ...}:
let
  baseDomain = "bksalman.com";
  domain = "headscale.bksalman.com";
in{
  services = {
    headscale = {
      enable = true;
      address = "0.0.0.0";
      port = 8080;
      settings = {
        server_url = "https://${domain}";
        dns_config.base_domain = baseDomain;
      };
      settings = { logtail.enabled = true; };
    };

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts.${domain} = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass =
              "http://localhost:${toString config.services.headscale.port}";
            proxyWebsockets = true;
          };
      };
    };
  };

  users.users.nginx.extraGroups = [ "acme" ];
  security.acme = {
    acceptTerms = true;
    defaults.email = "salman.f.abuhaimed@gmail.com";
  };

  environment.systemPackages = with pkgs; [
    headscale
    tcpdump
    openssl
  ];
}
