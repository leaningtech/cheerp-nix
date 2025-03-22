{ lib, stdenv, cmake, ninja, cheerp, wasm, sources, filterSrc }:

let
  name = if wasm then "cheerp-system-wasm" else "cheerp-system-js";
  toolchain =
    if wasm then "CheerpWasmToolchain.cmake" else "CheerpToolchain.cmake";
in stdenv.mkDerivation {
  pname = name;
  version = "master";

  src = filterSrc {
    root = sources.cheerp-libs;
    include = [ "system" ];
    exclude = [ "system/build" ];
  };
  sourceRoot = "source/system";

  nativeBuildInputs = [ cmake ninja ];

  configurePhase = ''
    cmake -B build -GNinja -DCMAKE_INSTALL_PREFIX=$out -DCMAKE_TOOLCHAIN_FILE=${cheerp}/share/cmake/Modules/${toolchain} -DCMAKE_BUILD_TYPE=Release .
    cd build
  '';

  meta = with lib; {
    homepage = "https://github.com/leaningtech/cheerp-compiler";
    description = ''
      A C++ compiler for the web";
    '';
    license = licenses.mit;
    platforms = with platforms; linux;
    maintainers = [ ];
  };
}
