{ config, pkgs, unstable, ... }:
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
  home.stateVersion = "22.11";

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
    unstable.vscode
    unstable.insomnia
    unstable.sqlx-cli
    unstable.dbeaver
    unstable.mpv
    unstable.frp
    unstable.prismlauncher # use unstable later
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
    unstable.discord
    zoxide
    krita
    # davinci-resolve
    piper
    spotify
    kdenlive
    unstable.chatterino2
    unstable.alacritty
    kitty
    plasma5Packages.bismuth
    unstable.obs-studio
    unstable.helix
    vim

    # fonts
    nerdfonts
  ];
}
