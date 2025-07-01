{ stdenv
, fetchFromGitHub
, cmake
}:
stdenv.mkDerivation rec {
  pname = "expat";
  version = "2.2.7";

  src = fetchFromGitHub {
    owner = "libexpat";
    repo = "libexpat";
    rev = "R_${builtins.replaceStrings ["."] ["_"] version}";
    sha256 = "sha256-Qnn4tITCqm+ADtvV5u4oPw0dc+EcZOxmZgZkY1Wnh7w=";
  };
  sourceRoot = "source/expat";
  cmakeFlags = [
    "-DCMAKE_C_BYTE_ORDER=LITTLE_ENDIAN"
    "-DBUILD_tests=OFF"
    "-DBUILD_examples=OFF"
    "-DBUILD_tools=OFF"
  ];
  # double // in paths in the .pc file trips nix
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace "$"'{prefix}/'"$"'{CMAKE_INSTALL_INCLUDEDIR}' "$"'{CMAKE_INSTALL_FULL_INCLUDEDIR}' \
      --replace "$"'{exec_prefix}/'"$"'{CMAKE_INSTALL_LIBDIR}' "$"'{CMAKE_INSTALL_FULL_LIBEDIR}'
  '';

  nativeBuildInputs = [ cmake ];

}
