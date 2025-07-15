{...}: {
  virtualisation.oci-containers = {
    containers.homeassistant = {
      volumes = ["home-assistant:/config"];
      environment.TZ = "Asia/Riyadh";
      image = "ghcr.io/home-assistant/home-assistant:stable";
      ports = [
        "8123:8123"
      ];
      extraOptions = [
        # Use the host network namespace for all sockets
        "--network=host"
        # Pass devices into the container, so Home Assistant can discover and make use of them
        # "--device=/dev/ttyACM0:/dev/ttyACM0"
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [8123];
}
