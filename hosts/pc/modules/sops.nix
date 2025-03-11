{...}: {
  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/salman/.config/sops/age/keys.txt";

    secrets = {
      sadmadbotlad-config = {
        owner = "salman";
      };
    };
  };
}
