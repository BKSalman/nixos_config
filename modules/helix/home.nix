{
  helix,
  config,
  ...
}: {
  programs.helix.package = helix.packages."x86_64-linux".default.overrideAttrs (oldAttrs: {
    buildFeatures = (oldAttrs.buildFeatures or []) ++ ["helix-term/git" "helix-term/steel"]; # enable steel as the plugin system language
  });
  # programs.helix.package = helix.packages."x86_64-linux".default;

  programs.helix.enable = true;

  home.file.".config/helix/languages.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_config/modules/helix/languages.toml";
  home.file.".config/helix/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_config/modules/helix/config.toml";
  home.file.".config/helix/cogs/keymaps.scm".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_config/modules/helix/cogs/keymaps.scm";
  home.file.".config/helix/init.scm".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_config/modules/helix/init.scm";
  home.file.".config/helix/helix.scm".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_config/modules/helix/helix.scm";

  home.file.".steel/cogs/package.scm".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_config/modules/helix/cogs/package.scm";
  home.file.".steel/cogs/picker.scm".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos_config/modules/helix/cogs/picker.scm";
}
