{ stdenv
, fetchurl
, pkg-config
, xorgproto
, libX11
, libXext
, libXrender
}:
stdenv.mkDerivation rec {
  pname = "libXrandr";
  version = "1.5.4";

  src = fetchurl {
    url = "mirror://xorg/individual/lib/${pname}-${version}.tar.xz";
    sha256 = "sha256-GtWwZTdfSoWRWqYGEcxkB8BgSSohTX+dryFL51LDtNM=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libX11
    libXext
    libXrender
  ];
  configureFlags = [
    "--disable-malloc0returnsnull"
  ];
}
