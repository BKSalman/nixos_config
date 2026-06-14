{config, ...}: {
  sops.secrets.pc-newt-env = {};

  services.newt = {
    enable = true;
    settings.endpoint = "https://pangolin.bksalman.com";
    environmentFile = config.sops.secrets.pc-newt-env.path;
  };
}
