{ lib
, pkgs
, clangStdenv
, ccacheClangStdenv
, ...
}@inputs:
let
  test = {
    conf.build = "test";
    stdenv = ccacheClangStdenv;
  };
  dev = {
    conf.build = "dev";
    stdenv = ccacheClangStdenv;
  };
  prod = {
    conf.build = "prod";
    stdenv = clangStdenv;
  };
  myScope = env: lib.makeScope lib.callPackageWith (self: pkgs // inputs // env);
  cheerpTest = (myScope test).callPackage ./cheerp {};
  cheerpDev = (myScope dev).callPackage ./cheerp {};
  cheerpProd = (myScope prod).callPackage ./cheerp {};
in
cheerpProd // {
    test = cheerpTest;
    dev = cheerpDev;
}
