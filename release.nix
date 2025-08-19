packages:
let
  cheerpPkgs = {
    inherit (packages)
      cheerp-compiler
      #cheerp-clangd
      cheerp-utils
      cheerp-musl-js
      cheerp-musl-wasm
      cheerp-runtimes-wasm
      cheerp-runtimes-js
      cheerp-webgl
      cheerp-wasm
      cheerp-stdlibs-wasm
      cheerp-stdlibs-js
      cheerp-system-wasm
      cheerp-system-js
      cheerp-asan
      cheerp-memprof
      cheerp
      unit-tests
      asan-tests
      ;
  };
  sysPkgsNestedXorg = packages.wasi.__buildSet;
  sysPkgs = (builtins.removeAttrs sysPkgsNestedXorg [ "xorg" ]) // (builtins.removeAttrs sysPkgsNestedXorg.xorg [ "recurseForDerivations" ]);
in
cheerpPkgs // sysPkgs
