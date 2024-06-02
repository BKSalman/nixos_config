{...}: {
  fileSystems."/home/salman/Documents/nfs" = {
    device = "192.168.0.221:/mnt/main/f";
    fsType = "nfs";
  };
}
