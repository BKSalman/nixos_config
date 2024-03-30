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
    systemd.user.services.sadmadfrontendlad = {
      Install.WantedBy = ["default.target"];
      Service = {
        ExecStart = "${sadmadbotlad.packages.x86_64-linux.server}/bin/server ${sadmadbotlad.packages.x86_64-linux.frontend}/ 8080";
        Restart = "always";
      };
    };

    systemd.user.services.sadmadbotlad = {
      Install.WantedBy = ["default.target"];
      Service = {
        ExecStart =
          "${sadmadbotlad.packages.x86_64-linux.default}/bin/sadmadbotlad "
          + "-c /home/salman/.config/sadmadbotlad/config.toml "
          + "--commands-path ${sadmadbotlad.packages.x86_64-linux.default}/share/commands "
          + "-db /home/salman/.config/sadmadbotlad/database.db";
        Restart = "always";
        Environment = "RUST_LOG=none,sadmadbotlad=debug";
      };
    };
  };
}
