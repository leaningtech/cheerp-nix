{ lib, stdenv, cheerp-compiler, wasm, sources, filterSrc }:

let
  target = if wasm then "cheerp-wasm" else "cheerp";
  install-target = if wasm then "install-bc" else "install-cheerp";
  name = if wasm then "cheerp-musl-wasm" else "cheerp-musl-js";
in stdenv.mkDerivation {
  pname = name;
  version = "master";

  src = filterSrc {
    root = sources.cheerp-musl;
    include = [ "configure" "Makefile" "arch" "include" "src" "crt" "tools" ];
  };

  nativeBuildInputs = [ ];

  configurePhase = ''
    mkdir build
    cd build
    RANLIB="${cheerp-compiler}/bin/llvm-ar s" AR="${cheerp-compiler}/bin/llvm-ar"  CC="${cheerp-compiler}/bin/clang -target ${target} --sysroot=${cheerp-compiler}" LD="${cheerp-compiler}/bin/llvm-link" CFLAGS="-Wno-int-conversion" ../configure --target=${target} --disable-shared --prefix=$out --with-malloc=dlmalloc
  '';
  installPhase = ''
    make ${install-target}
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
