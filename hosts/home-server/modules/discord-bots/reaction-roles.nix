{pkgs, ...}: {
  systemd.services.reaction-roles-bot = {
    enable = true;
    serviceConfig = {
      EnvironmentFile = config.age.secrets."reaction-roles.env".path;
      ExecStart = "${pkgs.reaction-roles}/bin/reaction-roles";
    };
  };

  containers.config.services.postgresql = {
    enable = true;
    settings = {
      port = 5445;
    };
  };
}
