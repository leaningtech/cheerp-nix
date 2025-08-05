{ stdenv
, fetchurl
, pkg-config
}:
stdenv.mkDerivation rec {
  pname = "xtrans";
  version = "1.5.2";

  src = fetchurl {
    url = "mirror://xorg/individual/lib/${pname}-${version}.tar.xz";
    sha256 = "sha256-XFy/40dkqRMdBI8DwxwZ5X+0xoLWdxPqtqZVQbTf+Gw=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ ];
}
