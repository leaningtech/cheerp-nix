{ stdenv
, fetchurl
, pkg-config
, python3
}:
stdenv.mkDerivation rec {
  pname = "xcb-proto";
  version = "1.17.0";

  src = fetchurl {
    url = "mirror://xorg/individual/xcb/${pname}-${version}.tar.xz";
    sha256 = "sha256-LBus0hEPR5n3TebrtxS5TPb4D7ESMWsSGUgP0iViFIw=";
  };

  nativeBuildInputs = [ pkg-config python3 ];
  buildInputs = [  ];
}
