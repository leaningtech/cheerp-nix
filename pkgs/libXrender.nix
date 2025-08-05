{ stdenv
, fetchurl
, pkg-config
, xorgproto
, libX11
}:
stdenv.mkDerivation rec {
  pname = "libXrender";
  version = "0.9.12";

  src = fetchurl {
    url = "mirror://xorg/individual/lib/${pname}-${version}.tar.xz";
    sha256 = "sha256-uDISjaSLOcjWCCJEgXQ0A60Wkb9OVU5L6cF03xcdG5c=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libX11
  ];
}
