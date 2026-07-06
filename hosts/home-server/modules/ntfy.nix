{
  config,
  pkgs,
  lib,
  ...
}: let
  domain = "ntfy.bksalman.com";
in {
  options = {
    ntfy.enable = lib.mkEnableOption "enable ntfy";
  };

  config = lib.mkIf config.ntfy.enable {
    services.ntfy-sh = {
      enable = true;
      settings = {
        listen-http = ":4030";
        base-url = "https://" + domain;
        upstream-base-url = "https://ntfy.sh";

        auth-file = "/var/lib/ntfy-sh/auth.db";
        auth-default-access = "deny-all";
      };
    };
  };
}
