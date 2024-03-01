{pkgs, ...}: {
  home.file.".config/leftwm/config.ron".source = ./config.ron;
  home.file.".config/leftwm/themes/current".source = ./horizon-dark;
  home.file.".config/polybar-scripts/pipewire-simple.sh" = {
    source = ./polybar-scripts/pipewire-simple.sh;
    executable = true;
  };
}
