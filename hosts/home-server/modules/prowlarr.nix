{
  pkgs,
  config,
  ...
}: {
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };
}
