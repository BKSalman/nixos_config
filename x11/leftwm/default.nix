{ pkgs , ... }: {
  services.xserver = {
    windowManager.leftwm.enable = true;
    displayManager.defaultSession = "none+leftwm";
  };

  environment.systemPackages = with pkgs; [
    haskellPackages.greenclip
 ];
}

