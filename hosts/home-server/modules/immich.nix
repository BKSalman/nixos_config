{
  config,
  pkgs,
  ...
}: let
  domain = "immich.bksalman.com";
in {
  services.nginx = {
    enable = true;
    clientMaxBodySize = "50000m";
    virtualHosts.${domain} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:2283";
        proxyWebsockets = true;
        extraConfig =
          # required when the target is also TLS server with multiple hosts
          "proxy_ssl_server_name on;"
          +
          # required when the server wants to use HTTP Authentication
          "proxy_pass_header Authorization;";
      };
    };
  };

  # for some reason I need to disable this for the GPU to work in the immich_machine_learning container
  systemd.enableUnifiedCgroupHierarchy = false;

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
