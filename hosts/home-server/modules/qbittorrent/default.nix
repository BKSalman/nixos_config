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
        Bittorrent = {
          Session = {
            BTProtocol = "TCP";
            GlobalDLSpeedLimit = 6500;
            GlobalUPSpeedLimit = 2000;
            Interface = "wg-mullvad";
            InterfaceName = "wg-mullvad";
            Preallocation = true;
            defaultSavePath = "${dataDir}/torrents";
            FinishedTorrentExportDirectory = "${dataDir}/torrents/complete";
            SubcategoriesEnabled = true;
          };
        };
        Preferences = {
          WebUI = {
            Password_PBKDF2 = "tyFVEcHist9pqAiag8t6eQ==:NJJpQEEZJiix+U0DYp+Rf4scPL1d+mY4iW/eDCNCNsQ9T55OqTDf3f2h7WA/EgR7zPzd2pRM3+mNBSR9Ziqh4w==";
          };
        };
        # queueingEnabled = false;
        # disableAutoTMMByDefault = false;
        # disableAutoTMMTriggersCategorySavePathChanged = false;
        # disableAutoTMMTriggersDefaultSavePathChanged = false;
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

    networking.wireguard.interfaces.wg-mullvad = {
      # Use a separate network namespace for the VPN.
      # sudo ip netns exec wg-qbittorrent curl --interface wg-mullvad https://am.i.mullvad.net/connected

      privateKeyFile = config.sops.secrets.wireguard-private-key.path;
      ips = ["10.70.98.176/32"];
      interfaceNamespace = "wg-qbittorrent";

      preSetup = ''
        ip netns add wg-qbittorrent
        ip -n wg-qbittorrent link set lo up
      '';

      postShutdown = ''
        ip netns delete wg-qbittorrent
      '';

      peers = [
        {
          publicKey = "VgNcwWy8MRhfEZY+XSisDM1ykX+uXlHQScOLqqGMLkc=";
          allowedIPs = ["0.0.0.0/0" "::0/0"];
          endpoint = "194.36.25.48:51820";
          persistentKeepalive = 25;
        }
      ];
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
