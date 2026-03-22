{config, ...}: {
  sops.secrets.newt-env = {};

  services.newt = {
    enable = true;
    settings.endpoint = "https://pangolin.bksalman.com";
    environmentFile = config.sops.secrets.newt-env.path;
  };
}
