{ stdenv
, fetchFromGitHub
, ruby_3_4
, autoreconfHook
, bison
}:
stdenv.mkDerivation rec {
  pname = "ruby";
  version = "3_4_5";

  src = fetchFromGitHub {
    owner = "ruby";
    repo = "ruby";
    rev = "v${version}";
    sha256 = "sha256-ZVcLlYTF+42HMn11CHM9CeJrjva61j10IeErBkcf03Y=";
  };
  patches = [ ./ruby.patch ];
  NIX_CFLAGS_COMPILE = "-Wno-implicit-function-declaration -O2 -flto -DUSE_TOKEN_THREADED_VM=0 -DOPT_THREADED_CODE=2";
  NIX_CFLAGS_LINK = "-cheerp-no-icf -cheerp-pretty-code -cheerp-linear-heap-size=256";
  configureFlags = [
    "--disable-shared"
    "-with-static-linked-ext"
    "--with-out-ext=json"
  ];

  nativeBuildInputs = [ autoreconfHook bison ruby_3_4 ];
}
