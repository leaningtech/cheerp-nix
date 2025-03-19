{ lib
, pkgs
, clangStdenv
, ccacheClangStdenv
, ...
}@inputs:
let
  getEnvString = envName: descr: default:
    let
      envVal = builtins.getEnv envName;
    in
    if envVal == "" || envVal == default
    then
      default
    else
      builtins.trace "Overriding option \"${descr}\" with \"${envVal}\" due to set \"${envName}\"" envVal;
  getEnvBool = envName: descr: default:
    let
      str = getEnvString envName descr (toString default);
    in
    str == "1";

  useCcache = getEnvBool "CHEERP_CCACHE" "Ccache build" false;
  doCheck = getEnvBool "CHEERP_CHECK" "Run checks" true;
  localCheerp = getEnvString "CHEERP_LOCAL_PATH" "Path to local cheerp-compiler build" "";
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
