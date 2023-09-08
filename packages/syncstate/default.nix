{ python3
, lib
}:
python3.pkgs.buildPythonApplication {
  pname = "syncstate";

  version = "0.0.1";

  format = "setuptools";

  src = ./.;

  meta = with lib; {
    platforms = platforms.linux;
  };
}