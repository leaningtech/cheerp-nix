{ lib, pkgs, stdenv, cheerp, sources, filterSrc }:

stdenv.mkDerivation {
  pname = "cheerp-webgl";
  version = "master";

  src = filterSrc {
    root = sources.cheerp-libs { inherit pkgs; };
    include = [ "webgles" ];
  };
  sourceRoot = "source/webgles";

  nativeBuildInputs = [ ];

  configurePhase = "";
  buildPhase = ''
    make INSTALL_PREFIX=$out CHEERP_PREFIX=${cheerp} all
  '';
  installPhase = ''
    make INSTALL_PREFIX=$out CHEERP_PREFIX=${cheerp} install
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
