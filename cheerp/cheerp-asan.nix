{ lib, stdenv, cmake, python3, cheerp, sources, filterSrc }:
stdenv.mkDerivation {
  pname = "cheerp-asan";
  version = "master";

  src = filterSrc {
    root = sources.cheerp-compiler;
    include = [
      "compiler-rt"
      "llvm/cmake"
      "llvm/utils"
      "llvm/lib/Demangle"
      "llvm/include"
      "cmake"
    ];
  };
  sourceRoot = "source/compiler-rt";

  nativeBuildInputs = [ cmake python3 ];

  configurePhase = ''
    cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$out" \
      -DCMAKE_TOOLCHAIN_FILE="${cheerp}/share/cmake/Modules/CheerpWasmToolchain.cmake" \
      -C CheerpCmakeConf.cmake
    cd build
  '';

  enableParallelBuilding = false;

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
