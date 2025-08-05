{ stdenv
, fetchurl
, pkg-config
, python3
, xcb-proto
, libXau
, libpthreadstubs
}:
stdenv.mkDerivation rec {
  pname = "libxcb";
  version = "1.17.0";

  src = fetchurl {
    url = "mirror://xorg/individual/lib/${pname}-${version}.tar.xz";
    sha256 = "sha256-WZ6/mZZxD+pxYi5uGE86itW0PQ5fqMTkBxI8iKWabVU=";
  };

  nativeBuildInputs = [ pkg-config python3 ];
  buildInputs = [ xcb-proto libXau libpthreadstubs ];
}
