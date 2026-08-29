{lib, ...}: {
  services.openssh = {
    enable = true;
    openFirewall = true;
    knownHosts = {
      alshaikh.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG6CRObYTJVKb84dLw0NhI5/0Fusr0hH4GQPw9xEzCKF";
      home-machine.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM4KRfVeUgRDU8euKHzsF38/1YA/+PEObYfkfAIA2+dg";
    };

    settings = {
      AcceptEnv = lib.mkForce ["LANG" "LC_*" "ZELLIJ"];
    };
  };
}
