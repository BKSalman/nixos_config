{ config, pkgs, masterpkgs, ... }:
{
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
  
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    # extraConfig = {
    #   credential = {
    #     credentialStore = "secretservice";
    #     helper = "${nur.repos.utybo.git-credential-manager}/bin/git-credential-manager-core";
    #   };
    # };
  };

  # TODO: move important stuff to system conf
  home.packages = with pkgs; [
    rustup
    jdk
    python311
    
    # waybar
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
    prismlauncher # use unstable later
    libsForQt5.ark
    libsecret
    nix-prefetch
    lazygit
    flameshot
    ngrok
    piper
    input-remapper
    libratbag
    gh
    exa
    discord
    zoxide
    krita
    # davinci-resolve
    piper
    spotify
    kdenlive
    chatterino2
    alacritty
    kitty
    plasma5Packages.bismuth
    obs-studio
    helix
    vim

    # fonts
    nerdfonts
  ];
}
