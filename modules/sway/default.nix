{
  lib,
  config,
  ...
}: {
  options = {
    sway.enable = lib.mkEnableOption "Enable sway";
  };

  config = lib.mkIf config.sway.enable {
    services.gnome.gnome-keyring.enable = true;

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };
  };
}
