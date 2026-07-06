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
    # ./deluge.nix
    ./minecraft.nix
    ./cloudflared.nix
    ./newt.nix
    ./paperless.nix
    ./proxmox.nix
    ./ryot.nix
    ./home-assistant.nix
    ./qbittorrent
    ./sabnzbd
    ./stirling-pdf
    ./recyclarr.nix
    ./seafile.nix
    ./ntfy.nix
  ];

  seafile.enable = true;
  minecraft.enable = false;
  cloudflared.enable = true;
  ntfy.enable = true;
}
