{
  pkgs,
  config,
  ...
}: {
  hardware = {
    opengl = {
      enable = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
        pipewire
      ];
    };
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      #   version = "555.42.02";
      #   sha256_64bit = "sha256-k7cI3ZDlKp4mT46jMkLaIrc2YUx1lh1wj/J4SVSHWyk=";
      #   sha256_aarch64 = "sha256-ekx0s0LRxxTBoqOzpcBhEKIj/JnuRCSSHjtwng9qAc0=";
      #   openSha256 = "sha256-3/eI1VsBzuZ3Y6RZmt3Q5HrzI2saPTqUNs6zPh5zy6w=";
      #   settingsSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
      #   persistencedSha256 = "sha256-3ae31/egyMKpqtGEqgtikWcwMwfcqMv2K4MVFa70Bqs=";
      # };

      modesetting.enable = true;
      powerManagement.enable = true;
      # open = true;
    };
  };

  services.xserver = {
    enable = true;
    videoDrivers = ["nvidia"];
  };

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    "nvidia.NVreg_EnableGpuFirmware=0"
  ];
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
  };
}
