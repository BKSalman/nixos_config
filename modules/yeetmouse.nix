{ config, pkgs, ... }:
let
  yeetmouse = pkgs.yeetmouse.override {
    inherit (config.boot.kernelPackages) kernel;
  };

  echo     = "${pkgs.coreutils}/bin/echo";
  modprobe = "${pkgs.kmod}/bin/modprobe";
  basename = "${pkgs.coreutils}/bin/basename";
  dirname  = "${pkgs.coreutils}/bin/dirname";

  setupKensington = pkgs.writeShellScriptBin "yeetmouse-setup" ''
    ${modprobe} yeetmouse

    USB_IF=$(${basename} "$(${dirname} "/sys$DEVPATH")")
    ${echo} "$USB_IF" > /sys/bus/usb/drivers/usbhid/unbind 2>/dev/null || true
    ${echo} "$USB_IF" > /sys/bus/usb/drivers/yeetmouse/bind

    ${echo} "1.0" > /sys/module/yeetmouse/parameters/Sensitivity
    ${echo} "0" > /sys/module/yeetmouse/parameters/AccelerationMode
    ${echo} "0.0" > /sys/module/yeetmouse/parameters/Acceleration
    ${echo} "1" > /sys/module/yeetmouse/parameters/update
  '';
in
{
  boot.extraModulePackages = [ yeetmouse ];
  boot.kernelModules = [ "yeetmouse" ];

  environment.systemPackages = [ yeetmouse ];

  services.udev.extraRules = ''
    ACTION=="add", \
      SUBSYSTEM=="hid", \
      ATTRS{name}=="Kensington ORBIT WIRELESS TB Mouse", \
      RUN+="${setupKensington}/bin/yeetmouse-setup"
  '';
}
