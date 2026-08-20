{
  config,
  pkgs,
  ...
}: {
  sops = {
    secrets = {
      nut-upsmon = {};
    };
  };

  ###########################################################################
  # 1. Keep the USB link alive: disable USB autosuspend so usbhid-ups
  #    doesn't lose the UPS. Global kernel param is the most robust option.
  ###########################################################################
  boot.kernelParams = ["usbcore.autosuspend=-1"];

  # Targeted alternative (instead of the global param): force power/control=on
  # for the APC device only. Uncomment if you prefer a scalpel to a hammer.
  # services.udev.extraRules = ''
  #   ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="051d", ATTR{idProduct}=="0003", TEST=="power/control", ATTR{power/control}="on"
  # '';

  ###########################################################################
  # 2. NUT / power.ups
  ###########################################################################
  power.ups = {
    enable = true;
    mode = "standalone"; # driver + upsd + upsmon on this one box

    # --- ups.conf ---
    ups.smc1000 = {
      driver = "usbhid-ups";
      port = "auto"; # usbhid-ups matches by USB, ignores port
      description = "APC Smart-UPS C SMC1000IC";
      directives = [
        # Match this specific UPS by USB IDs (helps if you add more later,
        # and documents the 0003 product id; change to 0004 if a firmware
        # update shifts it — check `lsusb`).
        "vendorid = 051d"
        "productid = 0003"

        # "Restore on AC" BIOS option needs the UPS to actually CUT power for
        # a few seconds. offdelay = seconds after killpower before output is
        # cut; ondelay = seconds after killpower before output returns when
        # mains is back. ondelay MUST be greater than offdelay.
        "offdelay = 60"
        "ondelay = 90"

        # Trigger shutdown at battery.charge = 50% (conservative for a hot
        # climate + aging battery). Requires ignorelb so upsmon respects this
        # threshold instead of only the UPS's built-in ~10% LB flag.
        "override.battery.charge.low = 50"
        "ignorelb"
      ];
    };

    # --- upsd.conf: listen on loopback only (standalone) ---
    upsd = {
      enable = true;
      listen = [
        {
          address = "127.0.0.1";
          port = 3493;
        }
        {
          address = "::1";
          port = 3493;
        }
      ];
    };

    # --- upsd.users (declared at power.ups.users, NOT power.ups.upsd.users) ---
    users.upsmon = {
      passwordFile = config.sops.secrets.nut-upsmon.path; # see secrets section
      upsmon = "primary";
    };

    # --- upsmon.conf: which UPS to monitor + how to react ---
    upsmon.monitor.smc1000 = {
      system = "smc1000@localhost";
      powerValue = 1;
      user = "upsmon";
      passwordFile = config.sops.secrets.nut-upsmon.path;
      type = "primary";
    };

    upsmon.settings = {
      MINSUPPLIES = 1;
      # SHUTDOWNCMD and POWERDOWNFLAG (=/run/killpower) come from module
      # defaults; you can override SHUTDOWNCMD if needed.
      DEADTIME = 30; # tolerate brief comms loss before declaring dead
      FINALDELAY = 5; # grace after SHUTDOWN notice before halt
      RBWARNTIME = 43200; # replace-battery reminder every 12 h
      NOCOMMWARNTIME = 300; # nag every 5 min if UPS unreachable
      NOTIFYFLAG = [
        ["ONLINE" "SYSLOG+WALL+EXEC"]
        ["ONBATT" "SYSLOG+WALL+EXEC"]
        ["LOWBATT" "SYSLOG+WALL+EXEC"]
        ["FSD" "SYSLOG+WALL+EXEC"]
        ["COMMBAD" "SYSLOG+WALL+EXEC"]
        ["COMMOK" "SYSLOG+WALL+EXEC"]
        ["SHUTDOWN" "SYSLOG+WALL+EXEC"]
        ["REPLBATT" "SYSLOG+WALL+EXEC"]
      ];
    };
  };
}
