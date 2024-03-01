#! reference: https://github.com/Icy-Thought/snowflake/blob/main/packages/tokyonight-gtk/default.nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  gtk-engine-murrine,
  jdupes,
  themeVariants ? [],
}: let
  inherit (lib) checkListOfEnum;
  inherit (builtins) toString;
in
  checkListOfEnum "$Tokyonight: GTK Theme Variants" [
    "Dark-B"
    "Dark-BL"
    "Dark-B-LB"
    "Dark-BL-LB"
    "Storm-B"
    "Storm-BL"
    "Storm-B-LB"
    "Storm-BL-LB"
  ]
  themeVariants
  stdenv.mkDerivation
  {
    pname = "tokyonight-gtk-theme";
    version = "unstable-2023-05-31";

    src = fetchFromGitHub {
      owner = "Fausto-Korpsvart";
      repo = "Tokyo-Night-GTK-Theme";
      rev = "e9790345a6231cd6001f1356d578883fac52233a";
      hash = "sha256-Q9UnvmX+GpvqSmTwdjU4hsEsYhA887wPqs5pyqbIhmc=";
    };

    nativeBuildInputs = [jdupes];

    propagatedUserEnvPkgs = [gtk-engine-murrine];

    installPhase = let
      gtkTheme = "Tokyonight-${toString themeVariants}";
    in ''
      runHook preInstall

      mkdir -p $out/share/themes

      cp -r -a $src/themes/${gtkTheme} $out/share/themes

      runHook postInstall
    '';

    meta = with lib; {
      description = "A GTK theme based on the Tokyo Night colour palette";
      homepage = "https://github.com/Fausto-Korpsvart/Tokyo-Night-GTK-Theme";
      license = licenses.gpl3Only;
      # maintainers = [ Icy-Thought ];
      platforms = platforms.all;
    };
  }
