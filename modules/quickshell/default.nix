{
  lib,
  config,
  ...
}: {
  options = {
    quickshell.enable = lib.mkEnableOption "Enable Quickshell";
  };

  config = lib.mkIf config.quickshell.enable {
    security.pam.services.quickshell-lock = {
      text = ''
        auth include login
      '';
    };
  };
}
