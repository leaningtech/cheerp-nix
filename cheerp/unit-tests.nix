{ lib, pkgs, stdenv, python3, nodejs, cheerp, sources, filterSrc }:

stdenv.mkDerivation {
  pname = "cheerp-unit-tests";
  version = "master";

  src = filterSrc {
    root = sources.cheerp-utils { inherit pkgs; };
    include = [ "tests" ];
  };

  nativeBuildInputs = [ python3 nodejs cheerp ];

  configurePhase = "";
  buildPhase = ''
    cd tests
    python3 run_tests.py -j $NIX_BUILD_CORES --all --asan clang++ node
  '';
  installPhase = ''
    mkdir -p $out
    cp testOut.out $out/
    cp testReport.test $out/
  '';

}
