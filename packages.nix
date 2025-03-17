{ lib
, pkgs
, clangStdenv
, ccacheClangStdenv
, ...
}@inputs:
let
  getEnvBool = envName: descr: default:
    let
      envVal = builtins.getEnv envName;
      boolVal = envVal == "1";
    in
    if boolVal == default
    then
      default
    else
      builtins.trace "Overriding option \"${descr}\" with \"${envVal}\" due to set \"${envName}\"" boolVal;

  useCcache = getEnvBool "CHEERP_CCACHE" "Ccache build" false;
  doCheck = getEnvBool "CHEERP_CHECK" "Run checks" true;
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
  cheerpDev = (myScope dev).callPackage ./cheerp { };
  cheerpProd = (myScope prod).callPackage ./cheerp { };
in
cheerpProd // {
  dev = cheerpDev;
}
