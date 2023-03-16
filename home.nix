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
    config.credential.helper = "libsecret";
  };

  
  home.packages = with pkgs; [
    # Rust
    rustup
    clang
    mold
    
    exa
    unstable.discord
    zoxide
    krita
    davinci-resolve
    minecraft
    vscode
    piper
    spotify
    kdenlive
    unstable.chatterino2
    kitty
    plasma5Packages.bismuth
    obs-studio
    unstable.helix
    vim
  ];
}
