{ stdenv
, fetchFromGitHub
, buildPackages
}:
let
  icu-version = "61.1";
  icu-src = fetchFromGitHub {
    owner = "unicode-org";
    repo = "icu";
    rev = "release-${builtins.replaceStrings ["."] ["-"] icu-version}";
    sha256 = "sha256-HpC3jUHnEAwopKiyxrEjmVnOIM16OHMYSDtYdBUqpOw=";
  };
  icu-native = buildPackages.stdenv.mkDerivation rec {
    pname = "icu-native";
    version = icu-version;

    src = icu-src;
    sourceRoot = "source/icu4c/source";

    nativeBuildInputs = [ ];

    installPhase = ''
      cp -r . $out
    '';
  };

in
stdenv.mkDerivation rec {
  pname = "icu";
  version = icu-version;

  src = icu-src;
  sourceRoot = "source/icu4c/source";

  nativeBuildInputs = [ ];

  postPatch = ''
    cp config/mh-linux config/mh-unknown
  '';
  preConfigure = ''
    export CXXFLAGS="-D__native_client__=1 -O2 -frtti"
  '';
  dontDisableStatic = true;
  configureFlags = [
    "--enable-static"
    "--disable-shared"
    "--disable-dyload"
    "--disable-renaming"
    "--with-cross-build=${icu-native}"
  ];
  buildPhase = ''
    make -j$NIX_BUILD_CORES lib
    make -j$NIX_BUILD_CORES -C common
  '';
  installPhase = ''
    make -j$NIX_BUILD_CORES -C common install
  '';
}
