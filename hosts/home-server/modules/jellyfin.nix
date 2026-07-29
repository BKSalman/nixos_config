{
  config,
  pkgs,
  lib,
  ...
}: let
  domain = "jellyfin.bksalman.com";
in {
  services.jellyfin = {
    enable = true;
    # dataDir = "/mnt/jellyfin";
    openFirewall = true;
    cacheDir = "/mnt/jellyfin/cache";
    group = "multimedia";
    hardwareAcceleration = {
      enable = true;
      type = "nvenc";
      device = "/dev/dri/renderD128";
    };
    transcoding = {
      enableHardwareEncoding = true;
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
      };
    };
  };

  systemd.services.jellyfin.serviceConfig.DeviceAllow = lib.mkForce [
    "/dev/nvidia0 rw"
    "/dev/nvidiactl rw"
    "/dev/nvidia-uvm rw"
    "/dev/nvidia-uvm-tools rw"
    "/dev/nvidia-modeset rw"
  ];

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8096";
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
