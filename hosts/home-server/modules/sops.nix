{
  config,
  lib,
  ...
}: {
  # to mount /home before the sops service runs
  # so it can look at the key file in /home
  fileSystems."/home".neededForBoot = true;

  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/salman/.config/sops/age/keys.txt";

    secrets = lib.mkMerge [
      {
        cloudflare-api-info = {
          owner = "acme";
        };
        vaultwarden-secrets = {
          owner = "vaultwarden";
        };
        stalwart-salman-secret = {
          # TODO: uncomment after stalwart test crash is resolved
          # owner = "stalwart-mail";
        };
        wireguard-private-key = {};
        gluetun-wg-config = {};
        gluetun-env = {};
        deluge-web-auth = {
          owner = "deluge";
        };
        cloudflared-home-server-reverse-proxy = {
          # owner = "cloudflared";
        };
        paperless-password = {
          owner = "paperless";
        };
      }
    ];
  };
}
