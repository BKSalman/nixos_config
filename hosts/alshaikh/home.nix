{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/helix
    ../../modules/mpv
    ../../modules/bash
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

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # gtk = {
  #   enable = true;
  #   # theme = {
  #   #   name = "Tokyonight-Dark-BL";
  #   #   package = pkgs.tokyonight-gtk.override {themeVariants = ["Dark-BL"];};
  #   # };
  # };

  # qt = {
  #   enable = true;
  #   platformTheme.name = "gtk";
  # };

  programs.obs-studio = {
    enable = true;
    plugins = [
      pkgs.obs-studio-plugins.wlrobs
    ];
  };

  # programs.firefox = {
  #   enable = true;
  #   package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
  #     forceWayland = true;
  #     extraPolicies = {
  #       ExtensionSettings = {};
  #     };
  #   };
  # };

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      #   dracula-theme.theme-dracula
      asvetliakov.vscode-neovim
      #   yzhang.markdown-all-in-one
    ];
  };

  # TODO: move important stuff to system conf
  home.packages = with pkgs; [
    jdk
    go
    cmake
    meson
    marksman

    difftastic
    alejandra
    fzf
    zellij
    tmux
    inkscape
    localsend
    ripgrep
    drawio
    hunspell
    hunspellDicts.en_US
    xcolor
    jq
    nh
    screenkey
    pdfarranger
    comma
    gf
    haskellPackages.greenclip
    networkmanagerapplet
    calc
    # just for pactl
    pulseaudio
    magic-wormhole
    libreoffice
    mediainfo
    brightnessctl
    wayvnc
    maliit-keyboard
    gimp
    direnv
    qmk
    tokei
    bottles
    fd
    kondo
    eww
    cliphist
    protonup-qt
    nodePackages_latest.bash-language-server
    yazi
    uxplay
    hwloc
    nix-index
    winetricks
    wineWowPackages.stable
    appimage-run
    ventoy-full
    gamescope
    ytdlp-gui
    ffmpeg_6-full
    thunderbird
    nixpkgs-review
    xdg-user-dirs
    ludusavi
    swww
    yt-dlp
    # mpvpaper
    pacman
    lolcat
    neofetch
    playerctl
    chromium
    pamixer
    mpc-cli
    ncmpcpp
    pavucontrol
    bat
    stremio
    lutris
    killall
    qimgv
    vopono
    onlyoffice-bin
    neovim
    btop
    nodejs
    mpv
    frp
    gh
    eza
    piper
    spotify
    chatterino2
    alacritty
    kitty
    vim
  ];

  # TODO: move to rofi directory
  home.file.".config/rofi/off.sh".source = ../../modules/rofi/off.sh;
  home.file.".config/rofi/launcher.sh".source = ../../modules/rofi/launcher.sh;
  home.file.".config/rofi/launcher_theme.rasi".source = ../../modules/rofi/launcher_theme.rasi;
  home.file.".config/rofi/clipboard_theme.rasi".source = ../../modules/rofi/clipboard_theme.rasi;
  home.file.".config/rofi/powermenu.sh".source = ../../modules/rofi/powermenu.sh;
  home.file.".config/rofi/powermenu_theme.rasi".source = ../../modules/rofi/powermenu_theme.rasi;

  home.file.".config/evremap/config.toml".source = ../../packages/evremap/config.toml;

  home.file.".local/bin/cliphist-rofi" = {
    text = ''
      #!/usr/bin/env bash

      if [ -z "$1" ]; then
          cliphist list
      else
          cliphist decode <<<"$1" | wl-copy
      fi
    '';
    executable = true;
  };

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

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.zoxide.enable = true;

  # programs.nushell.enable = true;

  programs.lazygit.enable = true;
}
