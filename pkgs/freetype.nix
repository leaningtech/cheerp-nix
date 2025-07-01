{ stdenv
, fetchurl
, pkg-config
, which
, gnumake
, zlib
, buildPackages
}:
stdenv.mkDerivation rec {
  pname = "freetype";
  version = "2.8.1";

  src = fetchurl {
    url = "mirror://savannah/${pname}/${pname}-${version}.tar.gz";
    sha256 = "sha256-h2cR0GSmob10vrGN038hmvJhAPctquvS2Gy0k9fNfsY=";
  };

  nativeBuildInputs = [ pkg-config which gnumake ];
  buildInputs = [ zlib ];
  preConfigure = ''
    export CC_BUILD="${buildPackages.stdenv.cc}/bin/cc"
  '';
  configureFlags = [
    "--with-harfbuzz=no"
    "--with-png=no"
    "--with-zlib=yes"
    "--with-bzip2=no"
  ];
}
