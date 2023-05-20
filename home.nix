{ config, pkgs, ... }:
{

  imports = [
    ./wayland/hyprland
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
      extensions = [ "rust-src" "rust-analyzer" ];
    })
    jdk
    (python311.withPackages (ps: with ps; [ pandas requests openpyxl mypy ]))
    go
    
    lapce
    eww-wayland
    cliphist
    protonup-qt
    teams
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
    mypaint
    nix-index
    winetricks
    wineWowPackages.stable
    # wineWowPackages.waylandFull
    # evremap
    appimage-run
    ventoy-full
    gamescope
    pureref
    python311Packages.python-lsp-server
    python311Packages.pylsp-mypy
    handbrake
    ytdlp-gui
    ffmpeg
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
    zenith-nvidia
    htop
    btop
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    nodePackages.svelte-language-server
    nodePackages.pnpm
    nodejs
    vscode
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
    # rofi-wayland
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
