{ stdenv
, fetchurl
, pkg-config
, xorgproto
, libX11
}:
stdenv.mkDerivation rec {
  pname = "libXext";
  version = "1.3.6";

  src = fetchurl {
    url = "mirror://xorg/individual/lib/${pname}-${version}.tar.xz";
    sha256 = "sha256-7bWfojmU5AX9xbQAr99YIK5hYLlPNePcPaRFehbol1M=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libX11
  ];
  configureFlags = [
    "--disable-malloc0returnsnull"
  ];
}
