pushd ~/system_config
  nix build .#homeConfigurations.salman.activationPackage
  ./result/activate
popd
