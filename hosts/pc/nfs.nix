{...}: {
  fileSystems."/home/salman/Documents/nfs" = {
    device = "192.168.0.225:/mnt/general";
    fsType = "nfs";
    options = [
      "nofail"
      "noauto"
      "x-systemd.automount" # mount on first access instead of at boot
      "x-systemd.idle-timeout=600" # unmount after 10min idle (optional)
      "_netdev" # tells systemd it needs network first
    ];
  };
}
