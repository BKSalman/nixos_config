{
  pkgs,
  leftwm,
  ...
}: {
  services.xserver.windowManager.leftwm.enable = true;
}
