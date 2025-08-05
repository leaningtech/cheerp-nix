{ stdenv
, fetchurl
, pkg-config
, xorgproto
}:
stdenv.mkDerivation rec {
  pname = "libXau";
  version = "1.0.12";

  src = fetchurl {
    url = "mirror://xorg/individual/lib/${pname}-${version}.tar.xz";
    sha256 = "sha256-dNDk36PTmtiTnpm9o39ZZ6ulKCEQdoKEZNJ3fUd/wPs=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ xorgproto ];
}
