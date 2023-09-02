{ ... }:
{
  # virtualisation.oci-containers = {
  #   containers = {
  #     "nextcloud" = {
  #       image = "nextcloud/all-in-one:latest";
  #       ports = [
  #         "80:80"
  #         "8080:8080"
  #         "8443:8443"
  #       ];
  #       volumes = [
  #         "nextcloud_aio_mastercontainer:/mnt/docker-aio-config"
  #         "/var/run/docker.sock:/var/run/docker.sock:ro"
  #       ];
  #     };
  #   };
  # };

  security.acme.defaults.email = "salman.f.abuhaimed@gmail.com";
  security.acme.acceptTerms = true;

  security.acme.certs."nextcloud.bksalman.com" = {
    dnsProvider = "cloudflare";
    credentialsFile = /home/salman/.config/.cloudflare;
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  users.users.nginx.extraGroups = [ "acme" ];

  services.nginx.virtualHosts = {
    "nextcloud.bksalman.com" = {
      useACMEHost = "nextcloud.bksalman.com";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:11000";
      };
    };
  };
}
