{ lib
, stdenvNoCC
, writeText
, callPackage
, cheerp
, cheerpPlatform
, ...
}:

argsFun:

let
  cheerpSetup = writeText "nix-support/setup-hook" ''
      export CHEERP_PREFIX="${cheerp}";
      export CC="${cheerp}/bin/clang";
      export CXX="${cheerp}/bin/clang++";
      export PATH="${cheerp}/libexec:$PATH";
  '';
  wrapDerivation = f:
    stdenvNoCC.mkDerivation (finalAttrs:
      f (lib.toFunction argsFun finalAttrs)
    );
  wrapper = wrapDerivation (
    { buildInputs ? [ ]
    , nativeBuildInputs ? [ ]
    , enableParallelBuilding ? true
    , meta ? { }
    , cmakeFlags ? [ ]
    , hostPlatform ? cheerpPlatform
    , ...
    } @ args:

    args //
    {

      pname = "cheerp-${lib.getName args}";
      version = lib.getVersion args;
      buildInputs = [ ] ++ buildInputs;
      nativeBuildInputs = [ cheerp cheerpSetup ] ++ nativeBuildInputs;

      cmakeFlags = [ ''-DCMAKE_TOOLCHAIN_FILE=${if hostPlatform==cheerpPlatform then "${cheerp}/share/cmake/Modules/CheerpToolchain.cmake" else "${cheerp}/share/cmake/Modules/CheerpWasmToolchain.cmake"}'' ] ++ cmakeFlags;

      # removes archive indices
      dontStrip = args.dontStrip or true;


      enableParallelBuilding = args.enableParallelBuilding or true;

    }
  );
in
  wrapper
