{ lib
, pkgs
, clangStdenv
, ccacheClangStdenv
, mylib
, ...
}@inputs:
let
  useCcache = mylib.env.getBool "CHEERP_CCACHE" "Ccache build" false;
  doCheck = mylib.env.getBool "CHEERP_CHECK" "Run checks" true;
  localCheerp = mylib.env.getString "CHEERP_LOCAL_PATH" "Path to local cheerp-compiler build" "";
  stdenv = if useCcache then ccacheClangStdenv else clangStdenv;
  dev = {
    conf = {
      build = "dev";
      inherit localCheerp;
      inherit doCheck;
    };
  };
  prod = {
    conf = {
      build = "prod";
      inherit localCheerp;
      inherit doCheck;
    };
  };
  myScope = env: lib.makeScope lib.callPackageWith (self: pkgs // inputs // { inherit stdenv; } // env);
  cheerpDev = (myScope dev).callPackage ./cheerp { };
  cheerpProd = (myScope prod).callPackage ./cheerp { };
in
cheerpProd // {
  dev = cheerpDev;
}
