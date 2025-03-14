{ lib
, stdenv
, cmake
, ninja
, python3
, cheerp
, wasm
, sources
, filterSrc
}:

let
  target = if wasm then "cheerp-wasm" else "cheerp";
  toolchain = if wasm then "CheerpWasmToolchain.cmake" else "CheerpToolchain.cmake";
  name = if wasm then "cheerp-runtimes-wasm" else "cheerp-runtimes-js";
in
stdenv.mkDerivation {
  pname = name;
  version = "master";
  
  src = filterSrc {
    root = sources.cheerp-compiler;
    include = [
      "runtimes"
      "libcxx"
      "libcxxabi"
      "llvm/cmake"
      "llvm/utils"
      "cmake"
    ];
  };
  sourceRoot = "source/runtimes";

  nativeBuildInputs = [ cmake ninja python3 ];

  configurePhase = ''
    cmake -S . -B build \
      -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_COLOR_DIAGNOSTICS=ON \
      -DCMAKE_CXX_COMPILER_TARGET="${target}" \
      -DCMAKE_TOOLCHAIN_FILE="${cheerp}/share/cmake/Modules/${toolchain}" \
      -DCMAKE_CXX_COMPILER="${cheerp}/bin/clang++" \
      -DCMAKE_C_COMPILER="${cheerp}/bin/clang" \
      -DCHEERP_PREFIX="${cheerp}" \
      -DCMAKE_INSTALL_PREFIX=$out \
      -C CheerpCmakeConf.cmake
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
