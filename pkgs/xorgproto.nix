{ stdenv
, fetchurl
, pkg-config
}:
stdenv.mkDerivation rec {
  pname = "xorgproto";
  version = "2024.1";

  src = fetchurl {
    url = "https://xorg.freedesktop.org/archive/individual/proto/xorgproto-${version}.tar.xz";
    sha256 = "sha256-NyIl/UCBW4QjVH9diQxd68cuiLkQiPv7ExWMIElcy1k=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ ];
}
