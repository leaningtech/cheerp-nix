{ lib
, pkgs
, clangStdenv
, ccacheClangStdenv
, ...
}@inputs:
let
  useCcache = (builtins.getEnv "CHEERP_CCACHE") == "1";
  doCheck = (builtins.getEnv "CHEERP_CHECK") != "0";
  stdenv = if useCcache then ccacheClangStdenv else clangStdenv;
  dev = {
    conf = {
      build = "dev";
      inherit doCheck;
    };
  };
  prod = {
    conf = {
      build = "prod";
      inherit doCheck;
    };
  };
  myScope = env: lib.makeScope lib.callPackageWith (self: pkgs // inputs // { inherit stdenv; } // env);
  cheerpDev = (myScope dev).callPackage ./cheerp {};
  cheerpProd = (myScope prod).callPackage ./cheerp {};
in
cheerpProd // {
    dev = cheerpDev;
}
