{ pkgs, config, ... }:
{
  services.nextcloud = {
    enable = true;
    hostName = "localhost";
    package = pkgs.nextcloud27;
    # Instead of using pkgs.nextcloud27Packages.apps,
    # we'll reference the package version specified above
    extraApps = with config.services.nextcloud.package.packages.apps; {
      inherit news contacts calendar tasks;
    };
    extraAppsEnable = true;
  };
}
