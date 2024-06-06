{...}: {
  fileSystems."/home/salman/Documents/nfs" = {
    device = "192.168.0.225:/mnt/general";
    fsType = "nfs";
  };
}
