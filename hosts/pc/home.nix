{
  config,
  pkgs,
  lib,
  ...
}: {
  # TODO: find a better way for home manager modules
  imports = [
    ../../modules/x11/leftwm/config.nix
    ../../modules/helix/home.nix
    ../../modules/zellij/home.nix
    ../../modules/bash/home.nix
    ../../modules/waybar/home.nix
    ../../modules/mpv/home.nix
    ../../modules/hyprland/home.nix
    ../../modules/jay/home.nix
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

  jay.enable = false;

  hyprland.enable = false;

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
  #   theme = {
  #     name = "Tokyonight-Dark-BL";
  #     package = pkgs.tokyonight-gtk.override {themeVariants = ["Dark-BL"];};
  #   };
  # };

  # qt.platformTheme.name = "gtk"; # qt5ct

  # programs.obs-studio = {
  #   enable = true;
  #   plugins = with pkgs; [
  #     obs-studio-plugins.wlrobs
  #     obs-text-pango
  #   ];
  # };

  programs.firefox = {
    enable = true;
  };

  # TODO: move important stuff to system conf
  home.packages = with pkgs; [
    jdk17
    (python311.withPackages (ps: with ps; [pandas requests openpyxl mypy]))
    go
    marksman
    deno

    difftastic
    alejandra
    arandr
    gf
    fm
    screenkey
    comma
    magic-wormhole
    wayvnc
    libreoffice-qt
    inkscape
    helvum
    sd
    # davinci-resolve
    audacity
    direnv
    grimblast
    hyprpicker
    qmk
    tokei
    fd
    kondo
    gifski
    eww
    cliphist
    protonup-qt
    wlsunset
    blender
    # nodePackages_latest.bash-language-server
    ranger
    # huiontablet
    uxplay
    jetbrains.idea-community
    hwloc
    nix-index
    # evremap
    appimage-run
    gamescope
    python311Packages.python-lsp-server
    python311Packages.pylsp-mypy
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
    zoom-us
    hyprpicker
    playerctl
    # cava
    chromium
    pamixer
    mpc-cli
    ncmpcpp
    webcord
    pavucontrol
    stremio
    # prusa-slicer
    # cura
    xclip
    # freecad
    killall
    # spice-gtk
    qimgv
    vopono
    nil
    onlyoffice-bin
    gdb
    lldb
    unzip
    neovim
    zenith-nvidia
    htop
    btop
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    nodePackages.svelte-language-server
    nodePackages.pnpm
    nodejs
    vscode
    sqlx-cli
    mpv
    frp
    prismlauncher
    lazygit
    flameshot
    ngrok
    piper
    libratbag
    gh
    eza
    discord
    zoxide
    starship
    piper
    spotify
    kdePackages.kdenlive
    chatterino2
    alacritty
    kitty
    # helix
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

  home.file.".local/bin/logout.sh".source = ./modules/virtual/logout.sh;

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

  # home.file.".local/share/applications/resolve.desktop".text = ''
  #   [Desktop Entry]
  #   Encoding=UTF-8
  #   Version=18.4.1
  #   Type=Application
  #   Terminal=false
  #   Exec=env QT_QPA_PLATFORM=xcb davinci-resolve
  #   Name=DaVinci Resolve
  # '';

  home.file.".config/starship.toml".source = ../../modules/starship.toml;

  home.file.".config/kitty/kitty.conf".source = ../../modules/kitty.conf;

  home.file.".ssh/config".text = ''
    Host aur.archlinux.org
    IdentityFile ~/.ssh/aur
    User aur
  '';
}
