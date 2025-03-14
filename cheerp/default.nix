{ lib
, stdenv
, mkShell
, writeShellScriptBin
, newScope
, conf
}:
lib.makeScope newScope (self:
  let
    callPackage = self.callPackage;
  in
  rec {
    cheerp-compiler = callPackage ./cheerp-compiler.nix {
      buildClangd = false;
    };

    cheerp-clangd = callPackage ./cheerp-compiler.nix {
      buildClangd = true;
    };

    cheerp-utils = callPackage ./cheerp-utils.nix {
      inherit cheerp-compiler;
    };

    cheerp-musl-js = callPackage ./cheerp-musl.nix {
      inherit cheerp-compiler;
      wasm = false;
    };
    cheerp-musl-wasm = callPackage ./cheerp-musl.nix {
      inherit cheerp-compiler;
      wasm = true;
    };

    cheerpStage = { name?"cheerp", libs }: callPackage ./cheerp.nix {
      name = "${name}-${conf.build}";
      inherit cheerp-compiler;
      inherit cheerp-utils;
      inherit libs;
    };

    cheerp-nomusl = cheerpStage {
      name = "cheerp-compiler+utils";
      libs = [ ];
    };

    cheerp-noruntimes = cheerpStage {
      name = "cheerp-compiler+utils+musl";
      libs = [ cheerp-musl-js cheerp-musl-wasm];
    };

    cheerp-runtimes-wasm = callPackage ./cheerp-runtimes.nix {
      cheerp = cheerp-noruntimes;
      wasm = true;
    };
    cheerp-runtimes-js = callPackage ./cheerp-runtimes.nix {
      cheerp = cheerp-noruntimes;
      wasm = false;
    };

    cheerp-nolibs = cheerpStage {
      name = "cheerp-compiler+utils+musl+runtimes";
      libs = [ cheerp-musl-js cheerp-musl-wasm cheerp-runtimes-js cheerp-runtimes-wasm ];
    };

    cheerp-webgl = callPackage ./cheerp-webgl.nix { cheerp = cheerp-nolibs; };
    cheerp-wasm = callPackage ./cheerp-wasm.nix { cheerp = cheerp-nolibs; };
    cheerp-stdlibs-wasm = callPackage ./cheerp-stdlibs.nix { cheerp = cheerp-nolibs; wasm = true; };
    cheerp-stdlibs-js = callPackage ./cheerp-stdlibs.nix { cheerp = cheerp-nolibs; wasm = false; };
    cheerp-system-wasm = callPackage ./cheerp-system.nix { cheerp = cheerp-nolibs; wasm = true; };
    cheerp-system-js = callPackage ./cheerp-system.nix { cheerp = cheerp-nolibs; wasm = false; };

    cheerp-noasan = cheerpStage {
      name = "cheerp-compiler+utils+musl+runtimes+libs";
      libs = [
        cheerp-musl-js cheerp-musl-wasm
        cheerp-runtimes-js cheerp-runtimes-wasm
        cheerp-stdlibs-js cheerp-stdlibs-wasm
        cheerp-system-wasm cheerp-system-js
        cheerp-webgl
        cheerp-wasm
      ];
    };

    cheerp-asan = callPackage ./cheerp-asan.nix { cheerp = cheerp-noasan; };

    cheerp-memprof = callPackage ./cheerp-memprof.nix { cheerp = cheerp-noasan;};

    cheerp = cheerpStage {
      libs = [
        cheerp-musl-js cheerp-musl-wasm
        cheerp-runtimes-js cheerp-runtimes-wasm
        cheerp-stdlibs-js cheerp-stdlibs-wasm
        cheerp-system-wasm cheerp-system-js
        cheerp-webgl
        cheerp-wasm
        cheerp-asan
        cheerp-memprof
      ];
    };

    unit-tests = callPackage ./cheerp-test.nix {
      cheerp = cheerp;
    };

    cheerp-proxy = writeShellScriptBin "cheerp" ''
      PATH=${cheerp}/bin/ exec "$@"
    '';


    devShell = mkShell {
      packages = [
        cheerp
        cheerp-clangd
      ];
    };

    cheerpPlatform = {
      config = "cheerp-leaningtech-webbrowser-genericjs";
    };
    cheerpWasmPlatform = {
      config = "cheerp-leaningtech-webbrowser-wasm";
    };
    cheerpWasiPlatform = {
      config = "cheerp-leaningtech-wasi-wasm";
    };
    mkGenericjs = callPackage ./stdenv.nix {
      inherit cheerpPlatform cheerpWasmPlatform cheerpWasiPlatform;
      inherit cheerp;
      hostPlatform = cheerpPlatform;
      targetPlatform = cheerpPlatform;
    };
    shell = mkGenericjs {
      name = "shell";
    };

  })
