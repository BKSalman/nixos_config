{helix, ...}: {
  programs.helix.package = helix.packages."x86_64-linux".default;
  programs.helix.enable = true;

  home.file.".config/helix/languages.toml".source = ./languages.toml;
  home.file.".config/helix/config.toml".source = ./config.toml;
  home.file.".config/helix/cogs/keymaps.scm".source = ./cogs/keymaps.scm;
  home.file.".config/helix/cogs/pacakge.scm".source = ./cogs/package.scm;
  home.file.".config/helix/init.scm".source = ./init.scm;
  home.file.".config/helix/helix.scm".source = ./helix.scm;
}
