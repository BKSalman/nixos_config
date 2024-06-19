{
  config,
  pkgs,
  ...
}: {
  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/salman/.config/sops/age/keys.txt";

    secrets = {
      nextcloud-admin-pass = {
        owner = "nextcloud";
      };
      cloudflare-api-info = {
        owner = "acme";
      };
      vaultwarden-secrets = {
        owner = "vaultwarden";
      };
      stalwart-salman-secret = {
        owner = "stalwart-mail";
      };
      wireguard-private-key = {};
    };
  };
}
