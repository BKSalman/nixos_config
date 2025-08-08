{
  pkgs,
  config,
  ...
}: let
  ryotPort = "4040";
  domain = "track.bksalman.com";
in {
  virtualisation.oci-containers.containers = {
    ryot-db = {
      image = "postgres:16-alpine";
      volumes = ["postgres_storage:/var/lib/postgresql/data"];
      extraOptions = [
        "--network=ryot-network"
      ];
      environmentFiles = [config.sops.secrets.ryot-db-env.path];
    };
    ryot = {
      image = "ignisda/ryot:v9";
      ports = ["${ryotPort}:8000"];
      extraOptions = [
        "--network=ryot-network"
      ];
      environmentFiles = [config.sops.secrets.ryot-env.path];
    };
  };

  systemd.services.init-ryot-network = let
    backend = config.virtualisation.oci-containers.backend;
    backendPkg =
      if backend == "docker"
      then pkgs.docker
      else pkgs.podman;
    backendService = "${backend}.service";
  in {
    description = "Create ryot network for containers";
    after = ["network.target" backendService];
    wants = [backendService];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    path = [backendPkg];
    script = ''
      # Check if network already exists
      if ! ${backend} network ls | grep -q ryot-network; then
        ${backend} network create ryot-network
      fi
    '';
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${ryotPort}";
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
