{...}: {
  imports = [
    ./nextcloud.nix
    ./sops.nix
    ./immich.nix
    ./jellyfin.nix
    ./homepage
    ./grafana.nix
    ./prometheus.nix
    # TODO: uncomment after stalwart test crash is resolved
    # ./mailserver.nix
    ./vaultwarden.nix
    ./prowlarr.nix
    ./sonarr.nix
    ./radarr.nix
    ./bazarr.nix
    ./deluge.nix
    ./minecraft.nix
  ];

  nextcloud.enable = false;
}
