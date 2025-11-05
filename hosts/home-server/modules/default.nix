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
    ./paperless.nix
    ./proxmox.nix
    ./ryot.nix
  ];

  minecraft.enable = false;
  cloudflared.enable = true;
}
