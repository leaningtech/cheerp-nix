{ lib, stdenv, cmake, ninja, cheerp-compiler, sources, filterSrc }:

stdenv.mkDerivation {
  pname = "cheerp-utils";
  version = "master";

  src = filterSrc {
    root = sources.cheerp-utils;
    include = [ "CMakeLists.txt" "include" "tools" "scripts" "tests" ];
  };

  nativeBuildInputs = [ cmake ninja ];

  configurePhase = ''
    mkdir -p $out
    # The cmake script will run $CMAKE_INSTALL_PREFIX/bin/clang++ to get the
    # compiler version, so temporarily add a link in $out to it
    ln -s ${cheerp-compiler}/bin $out/
    cmake -GNinja -B build -DCHEERP_PREFIX="${cheerp-compiler}" -DCMAKE_INSTALL_PREFIX=$out
    cd build
  '';
  installPhase = ''
    rm $out/bin
    ninja install
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
