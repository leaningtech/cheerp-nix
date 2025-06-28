{ lib, path, system, bintools-unwrapped, cheerp }:
let
  mkPlatform = mode: {
    config =
      if mode == "wasm" then
        "wasm32-unknown-none"
      else if mode == "genericjs" then
        "wasm32-unknown-none"
      else if mode == "wasm-wasi" then "wasm32-unknown-wasi"
      else throw "unknown mode";
    #system = "cheerp-genericjs";
    useLLVM = true;
    canExecute = plat: false;
    isStatic = true;
    isUnix = true;
    isLinux = true;
    isDarwin = false;
    uname = {
      system = "Cheerp";
      processor = "wasm32";
      release = "1";
    };
  };
  withOldMkDerivation =
    stdenvSuperArgs: k: stdenvSelf:
    let
      mkDerivationFromStdenv-super =
        stdenvSuperArgs.mkDerivationFromStdenv;
      mkDerivationSuper = mkDerivationFromStdenv-super stdenvSelf;
    in
    k stdenvSelf mkDerivationSuper;
  # Wrap the original `mkDerivation` providing extra args to it.
  extendMkDerivationArgs =
    old: f:
    withOldMkDerivation old (
      _: mkDerivationSuper: args:
      (mkDerivationSuper args).overrideAttrs f
    );
  mkDerivationWrapper = mode: old: extendMkDerivationArgs old (
    args: {
      dontStrip = true;
      configureFlags = (args.configureFlags or [ ]) ++ [
      ];
      makeFlags = (args.makeFlags or [ ]) ++ [
        "OBJEXT=o"
      ];
      cmakeFlags = [
        "-DCMAKE_MODULE_PATH=${cheerp}/share/cmake/Modules"
        "-DCMAKE_LINKER=${cheerp}/bin/llvm-link"
        "-DCMAKE_C_COMPILER_TARGET=cheerp-${mode}"
        "-DCMAKE_C_COMPILER_FRONTEND_VARIANT=GNU"
        "-DCMAKE_C_STANDARD_COMPUTED_DEFAULT=11"
        "-DCMAKE_C_COMPILER_ID_RUN=TRUE"
        "-DCMAKE_C_COMPILER_ID=Clang"
        "-DCMAKE_C_COMPILER_VERSION=16.0"
        "-DCMAKE_C_COMPILER_FORCED=FALSE"
        "-DCMAKE_CXX_COMPILER_TARGET=cheerp-${mode}"
        "-DCMAKE_CXX_COMPILER_FRONTEND_VARIANT=GNU"
        "-DCMAKE_CXX_STANDARD_COMPUTED_DEFAULT=11"
        "-DCMAKE_CXX_COMPILER_ID_RUN=TRUE"
        "-DCMAKE_CXX_COMPILER_ID=Clang"
        "-DCMAKE_CXX_COMPILER_VERSION=16.0"
        "-DCMAKE_CXX_COMPILER_FORCED=FALSE"
      ] ++ (args.cmakeFlags or [ ]);
    }
  );
  crossPkgs = mode: import path {
    crossSystem = mkPlatform mode;
    localSystem = system;
    config = {
      allowUnsupportedSystem = true;
      replaceCrossStdenv = { buildPackages, baseStdenv }:
        let
          stdenvNoCC = baseStdenv.override {
            buildPlatform = baseStdenv.buildPlatform;
            hostPlatform = baseStdenv.buildPlatform;
            targetPlatform = baseStdenv.targetPlatform;
            cc = null;
            hasCC = false;
          };
        in
        baseStdenv.override (old: {
          mkDerivationFromStdenv = mkDerivationWrapper mode old;
          cc = buildPackages.wrapCCWith {
            inherit stdenvNoCC;
            cc = cheerp;
            #isClang = true;
            isGNU = true;
            bintools = buildPackages.wrapBintoolsWith {
              inherit stdenvNoCC;
              bintools = bintools-unwrapped;
              libc = null;
            };
            libc = null;
            extraBuildCommands = ''
              echo "-target cheerp-${mode}" > $out/nix-support/cc-cflags
              echo "" > $out/nix-support/cc-ldflags
              echo "" > $out/nix-support/add-hardening.sh
            '';
            nativeTools = false;
            nativeLibc = false;
          };
        });
    };
    crossOverlays = [
      (final: prev: { })
    ];
  };
in
{
  wasm = crossPkgs "wasm";
  genericjs = crossPkgs "genericjs";
  wasi = crossPkgs "wasm-wasi";
}
