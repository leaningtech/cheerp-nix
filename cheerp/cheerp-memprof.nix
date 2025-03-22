{ lib, stdenv, cmake, ninja, cheerp, sources, filterSrc }:

stdenv.mkDerivation {
  pname = "cheerp-memprof";
  version = "master";

  src = filterSrc {
    root = sources.cheerp-libs;
    include = [ "memprof" ];
    exclude = [ "memprof/build" ];
  };
  sourceRoot = "source/memprof";

  nativeBuildInputs = [ cmake ninja ];

  configurePhase = ''
    cmake -B build -GNinja -DCMAKE_INSTALL_PREFIX=$out -DCMAKE_TOOLCHAIN_FILE=${cheerp}/share/cmake/Modules/CheerpWasmToolchain.cmake -DCMAKE_BUILD_TYPE=Release .
    cd build
  '';

  meta = with lib; {
    homepage = "https://github.com/leaningtech/cheerp-libs";
    description = ''
      A C++ compiler for the web";
    '';
    license = licenses.mit;
    platforms = with platforms; linux;
    maintainers = [ ];
  };
}
