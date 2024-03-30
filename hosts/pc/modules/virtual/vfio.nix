let
  # GTX 1650
  gpuIDs = [
    "10de:1f82" # Graphics
    "10de:10fa" # Audio
  ];
in
  {
    pkgs,
    lib,
    config,
    ...
  }: {
    options = {
      vfio.enable = lib.mkEnableOption "Enable VFIO";
    };

    config = lib.mkIf config.vfio.enable {
      environment.systemPackages = with pkgs; [
        libguestfs # needed to virt-sparsify qcow2 files
      ];

      boot = {
        kernelModules = [
          "vfio_pci"
          "vfio"
          "vfio_iommu_type1"
          "vfio_virqfd"
          "kvm-intel"

          "nvidia"
          "nvidia_modeset"
          "nvidia_uvm"
          "nvidia_drm"
        ];

        kernelParams = [
          # enable IOMMU
          "intel_iommu=on"
          "iommu=pt"
          # Hyperv (?)
          "kvm.ignore_msrs=1"

          # isolate GPU
          ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs)
        ];
      };

      hardware.opengl.enable = true;
      virtualisation.spiceUSBRedirection.enable = true;
    };
  }
