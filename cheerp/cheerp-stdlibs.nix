{ lib
, stdenv
, cheerp
, wasm
, sources
, filterSrc
}:

let
  name = if wasm then "cheerp-stdlibs-wasm" else "cheerp-stdlibs-js";
  build-target = if wasm then "asmjs" else "genericjs";
  install-target = if wasm then "install_asmjs" else "install_genericjs";
in
stdenv.mkDerivation {
  pname = name;
  version = "master";

  src = filterSrc {
    root = sources.cheerp-libs;
    include = [
      "stdlibs/Makefile"
    ];
  };
  sourceRoot = "source/stdlibs";

  nativeBuildInputs = [ ];

  configurePhase = ''
  '';
  buildPhase = ''
    make INSTALL_PREFIX=$out CHEERP_PREFIX=${cheerp} ${build-target}
  '';
  installPhase = ''
    mkdir -p $out/lib/${build-target}
    make INSTALL_PREFIX=$out CHEERP_PREFIX=${cheerp} ${install-target}
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
