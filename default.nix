{ system ? builtins.currentSystem
, lock ? ./npins/sources.json
, sources ? import ./npins { inherit lock; }
, nixpkgs ? sources.nixpkgs
}:
let
  pkgs = import nixpkgs {
    inherit system;

    overlays = [ (import ./ccache.nix) ];
    config.allowUnfree = true;
  };
  lib = import ./lib { inherit (pkgs) lib runCommand; };
  npins = import sources.npins {
    inherit system;
  };
  llvmPackages = pkgs.llvmPackages_17;
  ccacheClangStdenv = pkgs.ccacheStdenv.override {
    stdenv = llvmPackages.libcxxStdenv;
    bintools = llvmPackages.bintools;
  };
  clangStdenv = llvmPackages.libcxxStdenv;
  packages = pkgs.callPackage ./packages.nix {
    inherit clangStdenv;
    inherit ccacheClangStdenv;
    inherit llvmPackages;
    inherit sources;
    inherit (lib) filterSrc;
    mylib = lib;
  };
  devShells = {
    default = pkgs.mkShell {
      packages = [
        pkgs.just
        npins
      ];
    };
    compiler-dev = pkgs.mkShell.override { stdenv = ccacheClangStdenv; } {
      CHEERP_CCACHE = 1;
      CHEERP_CHECK = 0;
      shellHook = ''
        export CCACHE_BASEDIR=$PWD
      '';
      inputsFrom = with packages; [
        dev.cheerp-compiler
      ];
    };
    cheerp = pkgs.mkShell {
      packages = with packages; [
        cheerp
        cheerp-clangd
      ];
    };
  };
in
{
  inherit packages;
  inherit devShells;
  inherit lib;
  inherit pkgs;
  inputs.nixpkgs = nixpkgs;
}
