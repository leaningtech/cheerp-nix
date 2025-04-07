{ lib, stdenv, cmake, python3, llvmPackages, nodejs, cheerp, sources, conf, filterSrc }:
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

  nativeBuildInputs = [ cmake python3 llvmPackages.libllvm.dev nodejs ];

  configurePhase = ''
    cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$out" \
      -DLLVM_TOOLS_BINARY_DIR="${llvmPackages.libllvm.dev}/bin/" \
      -DCMAKE_TOOLCHAIN_FILE="${cheerp}/share/cmake/Modules/CheerpWasmToolchain.cmake" \
      -C CheerpCmakeConf.cmake
    cd build
  '';

  checkPhase = ''
    make -j $NIX_BUILD_CORES check-asan
  '';

  doCheck = conf.doCheck;

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
