{
  config,
  pkgs,
  lib,
  ...
}: let
  dataDir = "/mnt/media/torrent";
  domain = "qbittorrent.bksalman.com";
in {
  options = {
    qbittorrent.enable = lib.mkEnableOption "Enable qBittorrent";
  };

  config = lib.mkIf config.qbittorrent.enable {
    services.qbittorrent = {
      enable = true;
      group = "multimedia";

      serverConfig = {
        # LegalNotice.Accepted = true;
        BitTorrent = {
          Session = {
            GlobalDLSpeedLimit = 6500;
            GlobalUPSpeedLimit = 2000;
            Interface = "wg-mullvad";
            InterfaceName = "wg-mullvad";
            Preallocation = true;
            defaultSavePath = "${dataDir}/torrents";
            FinishedTorrentExportDirectory = "${dataDir}/torrents/complete";
            SubcategoriesEnabled = true;
            QueueingSystemEnabled = false;
            DisableAutoTMMByDefault = false;
            DisableAutoTMMTriggers.CategorySavePathChanged = false;
            DisableAutoTMMTriggers.DefaultSavePathChanged = false;
          };
        };
        Preferences = {
          WebUI = {
            Password_PBKDF2 = "tyFVEcHist9pqAiag8t6eQ==:NJJpQEEZJiix+U0DYp+Rf4scPL1d+mY4iW/eDCNCNsQ9T55OqTDf3f2h7WA/EgR7zPzd2pRM3+mNBSR9Ziqh4w==";
          };
        };
      };

      webuiPort = 4414;
      torrentingPort = 3313;
      openFirewall = true;
    };

    services.nginx.virtualHosts.${domain} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.qbittorrent.webuiPort}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
    };

    networking.firewall = {
      allowedUDPPorts = [config.networking.wg-quick.interfaces.wg-mullvad.listenPort];
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
  };
}
