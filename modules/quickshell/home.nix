{
  pkgs,
  config,
  quickshell,
  ...
}: {
  home.packages = with pkgs; [
    quickshell.packages."x86_64-linux".default
    kdePackages.qtdeclarative
  ];

  home.file.".config/quickshell" = {
    recursive = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_config/modules/quickshell/config";
  };
}
