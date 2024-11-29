{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./framework.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Riyadh";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ar_SA.UTF-8";
    LC_IDENTIFICATION = "ar_SA.UTF-8";
    LC_MEASUREMENT = "ar_SA.UTF-8";
    LC_MONETARY = "ar_SA.UTF-8";
    LC_NAME = "ar_SA.UTF-8";
    LC_NUMERIC = "ar_SA.UTF-8";
    LC_PAPER = "ar_SA.UTF-8";
    LC_TELEPHONE = "ar_SA.UTF-8";
    LC_TIME = "ar_SA.UTF-8";
  };

  # services.fprintd.enable = true;
  # services.fprintd.tod.enable = true;
  # security.pam.services.login.fprintAuth = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # services.desktopManager.cosmic.enable = true;
  # services.displayManager.cosmic-greeter.enable = true;

  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;

  environment.localBinInPath = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us,ara";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.salman = {
    isNormalUser = true;
    description = "salman";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [
      kate
      #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    easyeffects
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
