pushd ~/system_config
nix build .#homeManagerConfigurations.salman.activationPackage
./result/activate
popd
