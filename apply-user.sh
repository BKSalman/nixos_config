pushd ~/system-flake
nix build .#homeManagerConfigurations.salman.activationPackage
./result/activate
popd
