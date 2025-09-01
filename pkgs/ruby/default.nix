{ stdenv
, fetchFromGitHub
, fetchFromSavannah
, ruby_3_4
, autoreconfHook
, bison
}:
let
  rubygems = ruby_3_4.rubygems;
  config = fetchFromSavannah
    {
      repo = "config";
      rev = "576c839acca0e082e536fd27568b90a446ce5b96";
      sha256 = "11bjngchjhj0qq0ppp8c37rfw0yhp230nvhs2jvlx15i9qbf56a0";
    };
in
stdenv.mkDerivation rec {
  pname = "ruby";
  version = "3_4_5";

  src = fetchFromGitHub {
    owner = "ruby";
    repo = "ruby";
    rev = "v${version}";
    sha256 = "sha256-ZVcLlYTF+42HMn11CHM9CeJrjva61j10IeErBkcf03Y=";
  };
  postUnpack = ''
    rm -rf $sourceRoot/{lib,test}/rubygems*
    cp -r ${rubygems}/lib/rubygems* $sourceRoot/lib
  '';
  patches = [
    ./ruby.patch
    ./do-not-update-gems-baseruby.patch
  ];
  postPatch = ''
    sed -i configure.ac -e '/config.guess/d'
    cp --remove-destination ${config}/config.guess tool/
    cp --remove-destination ${config}/config.sub tool/
  '';
  NIX_CFLAGS_COMPILE = "-Wno-implicit-function-declaration -O2 -flto -DUSE_TOKEN_THREADED_VM=0 -DOPT_THREADED_CODE=2";
  NIX_CFLAGS_LINK = "-cheerp-no-icf -cheerp-pretty-code -cheerp-linear-heap-size=256";
  configureFlags = [
    "--disable-shared"
    "-with-static-linked-ext"
    "--with-out-ext=json"
  ];
  buildFlags = [ "V=1" ];

  nativeBuildInputs = [ autoreconfHook bison ruby_3_4 ];
}
