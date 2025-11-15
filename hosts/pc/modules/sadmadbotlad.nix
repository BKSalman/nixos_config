{
  sadmadbotlad,
  lib,
  config,
  ...
}: {
  options = {
    sadmadbotlad.enable = lib.mkEnableOption "Enable sadmadbotlad";
  };

  config = lib.mkIf config.sadmadbotlad.enable {
    systemd.user.services.sadmadbotlad = {
      wantedBy = ["default.target"];
      serviceConfig = {
        ExecStart =
          "${sadmadbotlad.packages.x86_64-linux.default}/bin/sadmadbotlad "
          + "-c ${config.sops.secrets.sadmadbotlad-config.path} "
          + "--commands-path ${sadmadbotlad.packages.x86_64-linux.default}/share/commands "
          + "--db /home/salman/.config/sadmadbotlad/database.db "
          + "-f 8080 "
          + "-s ${sadmadbotlad.packages.x86_64-linux.frontend}/ ";
        Restart = "always";
      };

      environment = {
        sadmadbotlad = "debug";
      };
    };
  };
}
