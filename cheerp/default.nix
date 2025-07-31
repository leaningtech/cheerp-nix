{ lib, stdenv, mkShell, writeShellScriptBin, symlinkJoin, newScope, conf }:
lib.makeScope newScope (self:
let callPackage = self.callPackage;
in rec {
  cheerp-compiler =
    callPackage ./cheerp-compiler.nix { buildClangd = false; };

  cheerp-clangd = callPackage ./cheerp-compiler.nix { buildClangd = true; };

  cheerp-utils = callPackage ./cheerp-utils.nix { inherit cheerp-compiler; };

  cheerp-musl-js = callPackage ./cheerp-musl.nix {
    inherit cheerp-compiler;
    wasm = false;
  };
  cheerp-musl-wasm = callPackage ./cheerp-musl.nix {
    inherit cheerp-compiler;
    wasm = true;
  };

  cheerp-compiler-local = stdenv.mkDerivation {
    name = "cheerp-compiler-local";
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/{bin,lib}
      ln -s ${conf.localCheerp}/lib/clang $out/lib/
      ln -s ${conf.localCheerp}/bin/clang $out/bin/
      ln -s ${conf.localCheerp}/bin/clang++ $out/bin/
      ln -s ${conf.localCheerp}/bin/llvm-link $out/bin/
      ln -s ${conf.localCheerp}/bin/llvm-ar $out/bin/
      ln -s ${conf.localCheerp}/bin/llvm-dis $out/bin/
      ln -s ${conf.localCheerp}/bin/llc $out/bin/
      ln -s ${conf.localCheerp}/bin/opt $out/bin/
    '';
  };

  cheerpStage = { name ? "cheerp", compiler ? cheerp-compiler, libs }:
    callPackage ./cheerp.nix
      {
        name = "${name}-${conf.build}";
        cheerp-compiler = compiler;
        inherit cheerp-utils;
        inherit libs;
      } // {
      local = callPackage ./cheerp.nix {
        name = "${name}-${conf.build}-local";
        cheerp-compiler = compiler;
        compiler-path = cheerp-compiler-local;
        inherit cheerp-utils;
        inherit libs;
      };
    };

  cheerp-nomusl = cheerpStage {
    name = "cheerp-compiler+utils";
    libs = [ ];
  };

  cheerp-noruntimes = cheerpStage {
    name = "cheerp-compiler+utils+musl";
    libs = [ cheerp-musl-js cheerp-musl-wasm ];
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
    libs = [
      cheerp-musl-js
      cheerp-musl-wasm
      cheerp-runtimes-js
      cheerp-runtimes-wasm
    ];
  };

  cheerp-webgl = callPackage ./cheerp-webgl.nix { cheerp = cheerp-nolibs; };
  cheerp-wasm = callPackage ./cheerp-wasm.nix { cheerp = cheerp-nolibs; };
  cheerp-stdlibs-wasm = callPackage ./cheerp-stdlibs.nix {
    cheerp = cheerp-nolibs;
    wasm = true;
  };
  cheerp-stdlibs-js = callPackage ./cheerp-stdlibs.nix {
    cheerp = cheerp-nolibs;
    wasm = false;
  };
  cheerp-system-wasm = callPackage ./cheerp-system.nix {
    cheerp = cheerp-nolibs;
    wasm = true;
  };
  cheerp-system-js = callPackage ./cheerp-system.nix {
    cheerp = cheerp-nolibs;
    wasm = false;
  };

  cheerp-noasan = cheerpStage {
    name = "cheerp-compiler+utils+musl+runtimes+libs";
    libs = [
      cheerp-musl-js
      cheerp-musl-wasm
      cheerp-runtimes-js
      cheerp-runtimes-wasm
      cheerp-stdlibs-js
      cheerp-stdlibs-wasm
      cheerp-system-wasm
      cheerp-system-js
      cheerp-webgl
      cheerp-wasm
    ];
  };

  cheerp-asan = callPackage ./cheerp-asan.nix { cheerp = cheerp-noasan; testMode = false; };

  cheerp-memprof =
    callPackage ./cheerp-memprof.nix { cheerp = cheerp-noasan; };

  cheerp = cheerpStage {
    libs = [
      cheerp-musl-js
      cheerp-musl-wasm
      cheerp-runtimes-js
      cheerp-runtimes-wasm
      cheerp-stdlibs-js
      cheerp-stdlibs-wasm
      cheerp-system-wasm
      cheerp-system-js
      cheerp-webgl
      cheerp-wasm
      cheerp-asan
      cheerp-memprof
    ];
  };

  unit-tests = callPackage ./unit-tests.nix { cheerp = cheerp; };

  asan-tests = callPackage ./cheerp-asan.nix { cheerp = cheerp; testMode = true; };

  tests = symlinkJoin {
    name = "cheerp-tests";
    paths = [ unit-tests asan-tests ];
  };

  cheerp-proxy = writeShellScriptBin "cheerp" ''
    PATH=${cheerp}/bin/ exec "$@"
  '';

  devShell = mkShell { packages = [ cheerp cheerp-clangd ]; };
})
