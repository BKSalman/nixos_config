{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/helix/home.nix
    ../../modules/mpv/home.nix
    ../../modules/bash/home.nix
    ../../modules/quickshell/home.nix
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

  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [
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
    calc
    # just for pactl
    pulseaudio
    magic-wormhole
    libreoffice
    mediainfo
    brightnessctl
    wayvnc
    direnv
    qmk
    tokei
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
    gamescope
    ytdlp-gui
    ffmpeg_6-full
    thunderbird
    nixpkgs-review
    xdg-user-dirs
    yt-dlp
    pacman
    lolcat
    neofetch
    playerctl
    chromium
    pamixer
    mpc
    ncmpcpp
    pavucontrol
    bat
    lutris
    killall
    qimgv
    vopono
    onlyoffice-desktopeditors
    neovim
    btop
    nodejs
    mpv
    frp
    gh
    piper
    spotify
    chatterino2
    alacritty
    kitty
    vim
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

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.zoxide.enable = true;

  programs.lazygit.enable = true;
}
