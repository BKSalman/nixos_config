{helix, ...}: {
  programs.helix.package = helix.packages."x86_64-linux".default;
  programs.helix.enable = true;

  home.file.".config/helix/languages.toml".source = ./languages.toml;
  home.file.".config/helix/config.toml".source = ./config.toml;
}
