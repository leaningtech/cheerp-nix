{ stdenv
, fetchFromGitHub
, pkg-config
, cmake
, libX11
}:
stdenv.mkDerivation rec {
  pname = "gl4es";
  version = "1.1.6";

  src = fetchFromGitHub {
    owner = "ptitSeb";
    repo = "gl4es";
    rev = "v${version}";
    sha256 = "sha256-epVj3aqz5PmO6VVX81V7jgGu0Dk/mGRJyYlGloJnsl8=";
  };

  patches = [ ./gl4es.patch ];
  # NOTE: remove once we bump version
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace 'cmake_minimum_required(VERSION 2.8.12)' 'cmake_minimum_required(VERSION 2.8.12...3.10)'
  '';
  cmakeFlags = [
    ''-DCMAKE_C_FLAGS="-DUSE_X11"''
  ];
  nativeBuildInputs = [ pkg-config cmake];
  buildInputs = [
    libX11
  ];
  installPhase = ''
    mkdir -p $out/lib
    cp ../lib/libGL.so.1 $out/lib/
  '';
}
