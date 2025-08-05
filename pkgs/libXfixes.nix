{ stdenv
, fetchurl
, pkg-config
, xorgproto
, libX11
}:
stdenv.mkDerivation rec {
  pname = "libXfixes";
  version = "6.0.1";

  src = fetchurl {
    url = "mirror://xorg/individual/lib/${pname}-${version}.tar.xz";
    sha256 = "sha256-tpX5PNJJlCGrAtInREWOZQzMiMHUyBMNYCACE6vALVg=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libX11
  ];
}
