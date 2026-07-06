{
  config,
  pkgs,
  lib,
  ...
}: {
  options = {
    ollama.enable = lib.mkEnableOption "enable ollama";
  };

  config = lib.mkIf config.ollama.enable {
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      package = pkgs.ollama-cuda;
    };
  };
}
