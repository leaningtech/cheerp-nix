{ lib, path, system, runCommand, bash, cheerp }:
let
  mkPlatform = mode: {
    config =
      if mode == "cheerp-wasm" then
        "wasm32-unknown-none"
      else if mode == "cheerp-genericjs" then
        "wasm32-unknown-none"
      else if mode == "cheerp-wasm-wasi" then
        "wasm32-unknown-wasi"
      else if mode == "wasm32-cheerpos-linux" then
        "wasm32-unknown-linux"
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
      enableParallelBuilding = args.enableParallelBuilding or true;
      configureFlags = (args.configureFlags or [ ]) ++ [
      ];
      makeFlags = (args.makeFlags or [ ]) ++ [
      ];
      cmakeFlags = [
        "-DCMAKE_MODULE_PATH=${cheerp}/share/cmake/Modules"
        "-DCMAKE_LINKER=${cheerp}/bin/llvm-link"
        "-DCMAKE_C_COMPILER_TARGET=${mode}"
        "-DCMAKE_C_COMPILER_FRONTEND_VARIANT=GNU"
        "-DCMAKE_C_STANDARD_COMPUTED_DEFAULT=11"
        "-DCMAKE_C_COMPILER_ID_RUN=TRUE"
        "-DCMAKE_C_COMPILER_ID=Clang"
        "-DCMAKE_C_COMPILER_VERSION=16.0"
        "-DCMAKE_C_COMPILER_FORCED=FALSE"
        "-DCMAKE_CXX_COMPILER_TARGET=${mode}"
        "-DCMAKE_CXX_COMPILER_FRONTEND_VARIANT=GNU"
        "-DCMAKE_CXX_STANDARD_COMPUTED_DEFAULT=11"
        "-DCMAKE_CXX_COMPILER_ID_RUN=TRUE"
        "-DCMAKE_CXX_COMPILER_ID=Clang"
        "-DCMAKE_CXX_COMPILER_VERSION=16.0"
        "-DCMAKE_CXX_COMPILER_FORCED=FALSE"
      ] ++ (args.cmakeFlags or [ ]);
      env.CHEERP_PREFIX=cheerp;
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
              bintools = runCommand "bintools" {} ''
                  mkdir -p $out/bin
                  ln -s ${cheerp}/bin/llvm-ar $out/bin/ar
                  ln -s ${cheerp}/bin/llvm-strip $out/bin/strip
                  ln -s ${cheerp}/bin/llvm-link $out/bin/ld
                  cat > $out/bin/ranlib << 'EOF'
                  #!${bash}/bin/bash
                  ${cheerp}/bin/llvm-ar s "$@"
                  EOF
              '';
              libc = null;
            };
            libc = null;
            extraBuildCommands = ''
              echo "-target ${mode} -flto" > $out/nix-support/cc-cflags
              echo "" > $out/nix-support/cc-ldflags
              echo "" > $out/nix-support/add-hardening.sh
            '';
            nativeTools = false;
            nativeLibc = false;
          };
        });
    };
    crossOverlays = [
      (import ./pkgs)
    ];
  };
in
{
  wasm = crossPkgs "cheerp-wasm";
  genericjs = crossPkgs "cheerp-genericjs";
  wasi = crossPkgs "cheerp-wasm-wasi";
  cheerpos = crossPkgs "wasm32-cheerpos-linux";
}
