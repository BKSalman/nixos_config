{
  pkgs,
  lib,
  config,
  ...
}: let
  domain = "home-assistant.bksalman.com";
  zigbee2mqtt-domain = "zigbee2mqtt.bksalman.com";
in {
  services.home-assistant = {
    enable = true;
    extraComponents = [
      # Components required to complete the onboarding
      "analytics"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
      # Recommended for fast zlib compression
      # https://www.home-assistant.io/integrations/isal
      "isal"
      "zha"
      "mqtt"
      "webostv"
    ];
    lovelaceConfig = {};
    customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
      mini-graph-card
      mini-media-player
      universal-remote-card
      mushroom
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};

      # "automation ui" = "!include automations.yaml";
      "scene ui" = "!include scenes.yaml";
      # "script ui" = "!include scripts.yaml";
    };
    openFirewall = true;
  };

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      homeassistant.enabled = config.services.home-assistant.enable;
      permit_join = true;
      serial = {
        port = "/dev/ttyUSB0";
      };
      frontend = {
        enabled = true;
        port = 8088;
      };
    };
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        acl = ["pattern readwrite #"];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  networking.firewall = {
    allowedTCPPorts = [
      1883
      8088
    ];
  };

  services.nginx = {
    virtualHosts.${domain} = {
      forceSSL = true;
      enableACME = true;
      extraConfig = ''
        proxy_buffering off;
      '';
      locations."/" = {
        proxyPass = "http://[::1]:8123";
        proxyWebsockets = true;
      };
    };
    virtualHosts.${zigbee2mqtt-domain} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8088";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
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
    certs.${zigbee2mqtt-domain} = {
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets.cloudflare-api-info.path;
      webroot = null;
      group = "nginx";
    };
  };
}
