{ lib, stdenv, symlinkJoin, python3, nodejs, cheerp, sources, filterSrc }:
let
  doTest = { set, asan }: stdenv.mkDerivation {
    pname = "cheerp-unit-tests-${set}${if asan then "-asan" else ""}";
    version = "master";

    src = filterSrc {
      root = sources.cheerp-utils;
      include = [ "tests" ];
    };

    nativeBuildInputs = [ python3 nodejs cheerp ];

    configurePhase = "";
    buildPhase = ''
      cd tests
      python3 run_tests.py -j $NIX_BUILD_CORES --${set} ${if asan then "--asan" else ""} clang++ node
    '';
    installPhase = ''
      mkdir -p $out
      cp testOut.out $out/
      cp testReport.test $out/
    '';

  };
  variants = [
    { set = "genericjs"; asan = false; }
    { set = "preexecute"; asan = false; }
    { set = "asmjs"; asan = false; }
    { set = "asmjs"; asan = true; }
    { set = "wasm"; asan = false; }
    { set = "wasm"; asan = true; }
    { set = "preexecute-asmjs"; asan = false; }
    { set = "preexecute-asmjs"; asan = true; }
  ];
  tests = builtins.listToAttrs (map
    (opts: {
      name = "${opts.set}${if opts.asan then "-asan" else ""}";
      value = doTest opts;
    })
    variants);
in
symlinkJoin
  {
    name = "cheerp-unit-tests";
    paths = builtins.attrValues tests;
  } // tests
