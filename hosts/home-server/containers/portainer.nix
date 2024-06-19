{...}: let
  domain = "portainer.bksalman.com";
in {
  virtualisation.oci-containers.containers.portainer = {
    image = "portainer/portainer-ce:latest";
    ports = [
      "8000:8000"
      "9443:9443"
    ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "portainer_data:/data"
    ];
  };
  networking.firewall.allowedTCPPorts = [9443];

  # services.nginx.virtualHosts.${domain} = {
  #   forceSSL = true;
  #   enableACME = true;
  #   locations."/" = {
  #     proxyPass = "http://127.0.0.1:8096";
  #     proxyWebsockets = true;
  #     recommendedProxySettings = true;
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
}
