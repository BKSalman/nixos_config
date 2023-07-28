{ config, pkgs, ... }:
{

  imports = [
    ./wayland/hyprland
    ./x11/leftwm/config.nix
    ./waybar
    ./helix
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

  gtk = {
    enable = true;
    theme = {
      name = "Tokyonight-Dark-BL";
      package = pkgs.tokyonight-gtk.override { themeVariants = [ "Dark-BL" ]; };
    };
  };

  qt.platformTheme = "gtk"; # qt5ct

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs; [
      obs-studio-plugins.wlrobs
      obs-studio-plugins.looking-glass-obs
      obs-studio-plugins.droidcam-obs
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

  # TODO: move important stuff to system conf
  home.packages = with pkgs; [
    (rust-bin.stable.latest.default.override {
      targets = [ "x86_64-unknown-linux-gnu" "wasm32-unknown-unknown" ];
      extensions = [ "rust-analyzer" "rust-src" "rust-std" ];
    })

    # rustup
    jdk
    (python311.withPackages (ps: with ps; [ pandas requests openpyxl mypy  python-lsp-server pylsp-mypy pip ]))
    go
    cmake
    meson
    rust-bindgen
    marksman

    calc
    termusic
    # just for pactl
    pulseaudio
    magic-wormhole
    nomachine-client
    dolphin
    libreoffice
    realvnc-vnc-viewer
    mediainfo
    glaxnimate
    brightnessctl
    wayvnc
    maliit-keyboard
    gimp
    direnv
    grimblast
    hyprpicker
    qmk
   tokei
    bottles
    fd
    kondo
    gifski
    lapce
    eww-wayland
    cliphist
    protonup-qt
    # teams
    wlsunset
    blender
    nodePackages_latest.bash-language-server
    ranger
    # huiontablet
    uxplay
    jetbrains.idea-community
    hwloc
    looking-glass-client
    grapejuice
    # nomachine-client
    microsoft-edge
    mypaint
    nix-index
    winetricks
    wineWowPackages.stable
    # wineWowPackages.waylandFull
    # evremap
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
    mpvpaper
    pacman
    lolcat
    neofetch
    zoom-us
    hyprpicker
    playerctl
    cava
    chromium
    pamixer
    mpc-cli
    ncmpcpp
    webcord
    pavucontrol
    bat
    stremio
    prusa-slicer
    cura
    lutris
    xclip
    freecad
    killall
    # spice-gtk
    qimgv
    vopono
    nil
    onlyoffice-bin
    gdb
    lldb
    unzip
    distrobox
    neovim
    htop
    btop
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    nodePackages.svelte-language-server
    nodePackages.pnpm
    nodejs
    # vscode
    insomnia
    sqlx-cli
    dbeaver
    mpv
    frp
    prismlauncher
    lazygit
    flameshot
    ngrok
    piper
    libratbag
    gh
    exa
    discord-canary
    zoxide
    starship
    # davinci-resolve
    piper
    spotify
    kdenlive
    chatterino2
    alacritty
    kitty
    plasma5Packages.bismuth
    # helix
    vim

    # Hyprland stuff
    hyprpaper
    mako
    # swayidle
    # swaylock-effects
    # wofi
    # waybar

  ];

  # TODO: move to rofi directory
  home.file.".config/rofi/off.sh".source = ./rofi/off.sh;
  home.file.".config/rofi/launcher.sh".source = ./rofi/launcher.sh;
  home.file.".config/rofi/launcher_theme.rasi".source = ./rofi/launcher_theme.rasi;
  home.file.".config/rofi/clipboard_theme.rasi".source = ./rofi/clipboard_theme.rasi;
  home.file.".config/rofi/powermenu.sh".source = ./rofi/powermenu.sh;
  home.file.".config/rofi/powermenu_theme.rasi".source = ./rofi/powermenu_theme.rasi;

  home.file.".inputrc".source = ./bash/.inputrc;

  home.file.".bashrc".source = ./bash/.bashrc;

  home.file.".config/evremap/config.toml".source = ./packages/evremap/config.toml;

  home.file.".local/bin/logout.sh".source = ./virtual/logout.sh;

  home.file.".local/bin/cliphist-rofi"= {
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
}
