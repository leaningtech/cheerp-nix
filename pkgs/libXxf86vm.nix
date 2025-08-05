{ stdenv
, fetchurl
, pkg-config
, xorgproto
, libX11
, libXext
}:
stdenv.mkDerivation rec {
  pname = "libXxf86vm";
  version = "1.1.6";

  src = fetchurl {
    url = "mirror://xorg/individual/lib/${pname}-${version}.tar.xz";
    sha256 = "sha256-lq9BTHPOHVRJrQS+f58n+oMw+ES23ahD7yLj4b77PuM=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libX11
    libXext
  ];
}
