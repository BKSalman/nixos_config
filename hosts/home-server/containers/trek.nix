{...}: {
  # Data directories
  systemd.tmpfiles.rules = [
    "d /mnt/trek 0755 root root -"
    "d /mnt/trek/data 0755 root root -"
    "d /mnt/trek/uploads 0755 root root -"
  ];

  # Docker container
  virtualisation.oci-containers.containers.trek = {
    image = "bksalman/trek:0.1.0-pre.2";
    ports = ["3001:3000"];
    volumes = [
      "/mnt/trek/data:/app/data"
      "/mnt/trek/uploads:/app/uploads"
    ];
    environment = {
      TZ = "Asia/Riyadh";
      PORT = "3000";
    };
  };
}
