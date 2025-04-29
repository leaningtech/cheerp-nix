{ lib, stdenv, cmake, python3, llvmPackages, nodejs, cheerp, sources, filterSrc, testMode }:
stdenv.mkDerivation {
  pname = if testMode then "cheerp-asan-tests" else "cheerp-asan";
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

  buildPhase = if testMode then ''
    make check-asan
  '' else ''
    make
  '';
  installPhase = if testMode then ''
    mkdir -p $out
    touch $out/passed
  '' else ''
    make install
  '';

  doCheck = false;

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
