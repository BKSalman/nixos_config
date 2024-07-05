{
  config,
  pkgs,
  ...
}: {
  systemd.services.cloudflare-ddns = {
    enable = true;
    wantedBy = [
      "multi-user.target"
    ];

    unitConfig = {
      Description = "Update DDNS on Cloudflare";
      ConditionPathExists = "${config.sops.secrets."config.json".path}";
      Wants = "network-online.target";
      After = "network-online.target";
    };

    serviceConfig = {
      Type = "oneshot";
      Environment = "CONFIG_PATH=${config.sops.secrets."config.json".path}";
      ExecStart = "${pkgs.cloudflare-ddns}/bin/cloudflare-ddns";
      User = "cloudflare-ddns";
    };
  };

  systemd.timers.cloudflare-ddns = {
    wantedBy = [
      "timers.target"
    ];

    unitConfig = {
      Description = "Update DDNS on Cloudflare every 15 minutes";
    };

    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "15m";
    };
  };

  users.users.cloudflare-ddns = {
    group = "cloudflare-ddns";
    isSystemUser = true;
  };
  users.groups.cloudflare-ddns.members = ["cloudflare-ddns"];
}
