{
  config,
  pkgs,
  lib,
  ...
}: {
  options = {
    vm.enable = lib.mkEnableOption "enable vm tools and tweaks";
  };

  config = lib.mkIf config.vm.enable {
    # Add user to libvirtd group
    users.users.salman.extraGroups = ["libvirtd"];

    # Install necessary packages
    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      virtio-win
      win-spice
      adwaita-icon-theme
    ];

    # Manage the virtualisation services
    virtualisation = {
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
        };
      };
      spiceUSBRedirection.enable = true;
    };
    services.spice-vdagentd.enable = true;

    # # Virtualbox
    # virtualisation.virtualbox.host = {
    #   enable = true;
    #   enableExtensionPack = true;
    # };
    # users.extraGroups.vboxusers.members = ["salman"];
  };
}
