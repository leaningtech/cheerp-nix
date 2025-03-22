{
  description = "Cheerp compiler nix flake";

  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, ... }@inputs: inputs.utils.lib.eachSystem [
    "x86_64-linux"
  ]
    (system:
      let
        default = import ./default.nix {
          inherit system;
          inherit nixpkgs;
        };
      in
      {
        legacyPackages = default.packages;
        inherit (default) devShells;
      });
}
