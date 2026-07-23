{config, ...}: let
  kernelPackage = config.boot.kernelPackages.kernel;
in {
  environment = {
    variables = {
      KDIR = "${kernelPackage.dev}/lib/modules/${kernelPackage.modDirVersion}/build";
    };

    systemPackages =
      kernelPackage.buildInputs
      ++ kernelPackage.nativeBuildInputs
      ++ kernelPackage.propagatedBuildInputs
      ++ kernelPackage.propagatedNativeBuildInputs;
  };
}

