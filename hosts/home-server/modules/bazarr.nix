{...}: {
  services.bazarr = {
    enable = true;
    openFirewall = true;
    group = "multimedia";
  };
}
