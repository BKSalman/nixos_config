{
  pkgs,
  config,
  lib,
  ...
}: {
  options = {
    jay.enable = lib.mkEnableOption "Enable jay configurations";
  };

  config = lib.mkIf config.jay.enable {
    home.file.".local/bin/wl-paste" = {
      text = ''
        #!/usr/bin/env bash
        jay run-privileged -- ${pkgs.wl-clipboard}/bin/wl-paste "$@"
      '';
      executable = true;
    };

    home.file.".local/bin/wl-copy" = {
      text = ''
        #!/usr/bin/env bash
        jay run-privileged -- ${pkgs.wl-clipboard}/bin/wl-copy "$@"
      '';
      executable = true;
    };

    home.file.".local/bin/obs-privileged" = {
      text = ''
        #!/usr/bin/env bash
        jay run-privileged -- obs "$@"
      '';
      executable = true;
    };

    home.file.".local/bin/discordj" = {
      text = ''
        #!/usr/bin/env bash
        jay run-privileged -- discord "$@"
      '';
      executable = true;
    };
  };
}
