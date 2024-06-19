{config, ...}: {
  virtualisation.oci-containers.containers = {
    gluetun = {
      name = "gluetun";
      image = "qmcgaw/gluetun";
      extraOptions = [
        "--device=/dev/net/tun"
        "--cap-add=NET_ADMIN"
      ];
      environmentFiles = [config.sops.secrets.gluetun-env.path];
    };
  };
}
