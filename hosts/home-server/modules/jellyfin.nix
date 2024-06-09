{
  config,
  pkgs,
  ...
}: {
  services.jellyfin = {
    enable = true;
    dataDir = "/mnt/jellyfin";
    openFirewall = true;
  };
}
