{
  config,
  lib,
  pkgs,
  ...
}: let
  domain = "sab.bksalman.com";
  dataDir = "/mnt/media/news";

  # Network namespace configuration
  nsName = "vpn-sab";
  vethHost = "veth-sab-host";
  vethNs = "veth-sab-ns";
  hostIp = "10.200.1.1";
  nsIp = "10.200.1.2";
  sabPort = 2142;
in {
  # Create the network namespace and veth pair
  systemd.services."netns-${nsName}" = {
    description = "Network namespace for SABnzbd";
    before = ["wg-quick-wg-${nsName}.service" "sabnzbd.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "netns-up" ''
        ${pkgs.iproute2}/bin/ip netns add ${nsName} || true

        # Create veth pair
        ${pkgs.iproute2}/bin/ip link add ${vethHost} type veth peer name ${vethNs}

        # Move one end into the namespace
        ${pkgs.iproute2}/bin/ip link set ${vethNs} netns ${nsName}

        # Configure host side
        ${pkgs.iproute2}/bin/ip addr add ${hostIp}/24 dev ${vethHost}
        ${pkgs.iproute2}/bin/ip link set ${vethHost} up

        # Configure namespace side
        ${pkgs.iproute2}/bin/ip -n ${nsName} addr add ${nsIp}/24 dev ${vethNs}
        ${pkgs.iproute2}/bin/ip -n ${nsName} link set ${vethNs} up
        ${pkgs.iproute2}/bin/ip -n ${nsName} link set lo up

        # Default route in namespace points to host (will be overridden by WG for most traffic)
        ${pkgs.iproute2}/bin/ip -n ${nsName} route add default via ${hostIp}
      '';
      ExecStop = pkgs.writeShellScript "netns-down" ''
        ${pkgs.iproute2}/bin/ip link del ${vethHost} || true
        ${pkgs.iproute2}/bin/ip netns del ${nsName} || true
      '';
    };
  };

  # WireGuard inside the namespace
  systemd.services."wg-quick-wg-${nsName}" = {
    description = "WireGuard VPN in ${nsName} namespace";
    after = ["netns-${nsName}.service"];
    requires = ["netns-${nsName}.service"];
    before = ["sabnzbd.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "wg-up" ''
        # Create wireguard interface inside the namespace
        ${pkgs.iproute2}/bin/ip link add wg-${nsName} type wireguard
        ${pkgs.iproute2}/bin/ip link set wg-${nsName} netns ${nsName}

        # Configure wireguard
        ${pkgs.iproute2}/bin/ip netns exec ${nsName} ${pkgs.wireguard-tools}/bin/wg set wg-${nsName} \
          private-key ${config.sops.secrets.wireguard-private-key.path} \
          peer TDHn9OvFYoHh9nwlYG7OCpPRvCjfODUOksSQPzhguTg= \
          endpoint 149.102.229.158:51820 \
          allowed-ips 0.0.0.0/0,::/0 \
          persistent-keepalive 25

        # Assign addresses and bring up
        ${pkgs.iproute2}/bin/ip -n ${nsName} addr add 10.68.23.177/32 dev wg-${nsName}
        ${pkgs.iproute2}/bin/ip -n ${nsName} addr add fc00:bbbb:bbbb:bb01::5:17b0/128 dev wg-${nsName}
        ${pkgs.iproute2}/bin/ip -n ${nsName} link set wg-${nsName} up

        # Route all traffic through WG, except traffic to host veth (for nginx proxy)
        ${pkgs.iproute2}/bin/ip -n ${nsName} route add ${hostIp}/32 dev ${vethNs}
        ${pkgs.iproute2}/bin/ip -n ${nsName} route replace default dev wg-${nsName}
      '';
      ExecStop = pkgs.writeShellScript "wg-down" ''
        ${pkgs.iproute2}/bin/ip -n ${nsName} link del wg-${nsName} || true
        rm -rf /etc/netns/${nsName} || true
      '';
    };
  };

  # NAT for the namespace to reach the VPN endpoint initially
  networking.nat = {
    enable = true;
    internalInterfaces = [vethHost];
    externalInterface = "eth0"; # Change to your actual external interface
  };

  # Firewall: allow forwarding for the veth
  networking.firewall.extraCommands = ''
    iptables -A FORWARD -i ${vethHost} -o wg-${nsName} -j ACCEPT || true
    iptables -A FORWARD -i wg-${nsName} -o ${vethHost} -j ACCEPT || true
  '';

  services.sabnzbd = {
    enable = true;
    group = "multimedia";
    secretFiles = [
      config.sops.secrets.sab-config.path
    ];
    settings = {
      misc = {
        port = sabPort;
        bandwidth_max = "50MB/s";
        host_whitelist = "${domain}";
        download_dir = "${dataDir}/incomplete";
        complete_dir = "${dataDir}/complete";
        # Bind to the namespace IP so it's accessible via veth
        host = "0.0.0.0";
      };
    };
  };

  # Run SABnzbd inside the network namespace
  systemd.services.sabnzbd = {
    after = ["wg-quick-wg-${nsName}.service"];
    requires = ["wg-quick-wg-${nsName}.service"];
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/${nsName}";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.services.sabnzbd.settings.misc.download_dir} 0775 sabnzbd multimedia -"
    "d ${config.services.sabnzbd.settings.misc.complete_dir} 0775 sabnzbd multimedia -"
  ];

  # Nginx proxies to SABnzbd through the veth link
  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://${nsIp}:${builtins.toString sabPort}";
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
