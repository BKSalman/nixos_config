{...}: {
  # to mount /home before the sops service runs
  # so it can look at the key file in /home
  fileSystems."/home".neededForBoot = true;

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
