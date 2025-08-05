{ stdenv
, fetchurl
, pkg-config
, xorgproto
, libpthreadstubs
, libxcb
, xtrans
, buildPackages
}:
stdenv.mkDerivation rec {
  pname = "libX11";
  version = "1.8.10";

  src = fetchurl {
    url = "mirror://xorg/individual/lib/${pname}-${version}.tar.xz";
    sha256 = "sha256-Kzs9rZNH20HcpWvrfbWHjyg73hFC8E2fjkeK9DXf3FM=";
  };

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpthreadstubs
    libxcb
    xtrans
  ];
  patches = [ ./libX11.patch ];
  configureFlags = [
    "--disable-malloc0returnsnull"
  ];
}
