{ system ? builtins.currentSystem
, lock? ./npins/sources.json
, sources? import ./npins { inherit lock; }
, nixpkgs ? sources.nixpkgs
}:
let
  pkgs = import nixpkgs {
    inherit system;

    overlays = [ (import ./ccache.nix) ];
    config.allowUnfree = true;
  };
  npins = import sources.npins {
    inherit system;
  };
  filterSrc' = import ./nix-filter.nix;
  filterSrc = { root, include ? [ ], exclude ? [ ] }:
    if builtins.isPath root then
      let
        makePaths = l:
          map (p: fs.maybeMissing (root + "/${p}")) l;
        fs = pkgs.lib.fileset;
      in
      fs.toSource {
        root = root;
        fileset = fs.difference (fs.unions (makePaths include)) (fs.unions (makePaths exclude));
      }
    else
      filterSrc' { inherit root include exclude; };
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
    inherit filterSrc;
  };
  devShells = {
    default = pkgs.mkShell {
      CHEERP_CCACHE=1;
      CHEERP_CHECK=0;
      packages = [
        pkgs.just
        npins
      ];
    };
    compiler-dev = pkgs.mkShell.override { stdenv = ccacheClangStdenv; } {
      CHEERP_CCACHE=1;
      CHEERP_CHECK=0;
      CCACHE_NOLINK=1;
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
}
