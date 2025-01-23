{
  config,
  lib,
  ...
}: {
  options = {
    cloudflared.enable = lib.mkEnableOption "Enable cloudflared container";
  };

  config = lib.mkIf config.cloudflared.enable {
    services.cloudflared = {
      enable = true;
      tunnels = {
        "e33ec508-0d36-49cf-9367-6dd95bcced08" = {
          default = "http_status:404";
          credentialsFile = config.sops.secrets.cloudflared-home-server-reverse-proxy.path;
          ingress = {
            "bitwarden.bksalman.com" = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
          };
        };
      };
    };
  };
}
