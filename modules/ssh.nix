{lib, ...}: {
  services.openssh = {
    enable = true;
    ports = [222];
    openFirewall = true;
    knownHosts = {
      alshaikh.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAVPe6Tcsh7X89G6mjfurhez2Md9/VV6CxWIaDXdZfa";
      home-machine.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJkV9LhQ+F3F9dWbpuqKQSkGaCSy9HWPmllFSYemLo5";
    };

    settings = {
      AcceptEnv = lib.mkForce ["LANG" "LC_*"];
    };
  };
}
