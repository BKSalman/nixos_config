{...}: {
  imports = [
    ./sops.nix
    ./immich.nix
    ./jellyfin.nix
    ./homepage
    ./grafana.nix
    ./prometheus.nix
    ./vaultwarden.nix
    ./prowlarr.nix
    ./sonarr.nix
    ./radarr.nix
    ./bazarr.nix
    ./deluge.nix
    ./minecraft.nix
    ./cloudflared.nix
    ./seafile.nix
    ./paperless.nix
    ./proxmox.nix
  ];

  seafile.enable = true;
  minecraft.enable = false;
  cloudflared.enable = true;
}
