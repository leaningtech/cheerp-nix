{ stdenv
, fetchurl
, pkg-config
, xorgproto
, libX11
, libXfixes
, libXrender
}:
stdenv.mkDerivation rec {
  pname = "libXcursor";
  version = "1.2.3";

  src = fetchurl {
    url = "mirror://xorg/individual/lib/${pname}-${version}.tar.xz";
    sha256 = "sha256-/elALdTP552nHi2Wu5gK/F5v9Pin10wVnhlmr7KywsA=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libX11
    libXfixes
    libXrender
  ];
}
