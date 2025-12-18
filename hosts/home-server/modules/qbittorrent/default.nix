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

    networking.wg-quick.interfaces.wg-mullvad = {
      # Use a separate network namespace for the VPN.
      # sudo ip netns exec wg-qbittorrent curl --interface wg-mullvad https://am.i.mullvad.net/connected
      table = "vpn";

      privateKeyFile = config.sops.secrets.wireguard-private-key.path;
      address = ["10.68.23.177/32" "fc00:bbbb:bbbb:bb01::5:17b0/128"];

      listenPort = 51820;

      peers = [
        {
          publicKey = "TDHn9OvFYoHh9nwlYG7OCpPRvCjfODUOksSQPzhguTg=";
          allowedIPs = ["0.0.0.0/0" "::0/0"];
          endpoint = "149.102.229.158:51820";
          persistentKeepalive = 25;
        }
      ];
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
