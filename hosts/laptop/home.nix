{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/nix/home.nix
    ../../modules/helix/home.nix
    ../../modules/mpv/home.nix
    ../../modules/bash/home.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "salman";
  home.homeDirectory = "/home/salman";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # home.pointerCursor = {
  #   enable = true;
  #   name = "Adwaita";
  #   package = pkgs.adwaita-icon-theme;
  #   size = 24;
  #   gtk.enable = true;
  #   x11.enable = true;
  # };

  gtk = {
    enable = true;
    # theme = {
    #   name = "Tokyonight-Dark-BL";
    #   package = pkgs.tokyonight-gtk.override {themeVariants = ["Dark-BL"];};
    # };
  };

  home.packages = with pkgs; [
    fzf
    zellij
    localsend
    ripgrep
    hunspell
    hunspellDicts.en_US
    jq
    # just for pactl
    pulseaudio
    magic-wormhole
    mediainfo
    fd
    cliphist
    yazi
    uxplay
    nix-index
    appimage-run
    ffmpeg_6-full
    xdg-user-dirs
    yt-dlp
    playerctl
    chromium
    pamixer
    mpc
    pavucontrol
    bat
    killall
    qimgv
    nil
    unzip
    btop
    mpv
    gh
    eza
    kdePackages.kate
    alacritty
    kitty
  ];

  home.file.".local/share/applications/uxplay.desktop".text = ''
    [Desktop Entry]
    Encoding=UTF-8
    Version=1.0
    Type=Application
    Terminal=false
    Exec=uxplay -p
    Name=UXplay
    Icon=~/.local/share/applications/Airplay.png
  '';

  home.file.".config/starship.toml".source = ../../modules/starship.toml;

  programs.lazygit.enable = true;
}
