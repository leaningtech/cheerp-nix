{ stdenv
, fetchFromGitHub
, cmake
}:
stdenv.mkDerivation rec {
  pname = "harfbuzz";
  version = "10.1.0";
  src = fetchFromGitHub {
    owner = "harfbuzz";
    repo = "harfbuzz";
    rev = version;
    sha256 = "sha256-MBHNbS2aPYqzakiKplh6rZUEebk4kzON4u9hBJgq91Q=";
  };
  nativeBuildInputs = [ cmake ];
}
