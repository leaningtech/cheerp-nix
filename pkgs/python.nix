{ stdenv
, fetchFromGitHub
, buildPackages
}:
stdenv.mkDerivation rec {
  pname = "python";
  version = "3.12";

  src = fetchFromGitHub {
    owner = "python";
    repo = "cpython";
    rev = version;
    sha256 = "sha256-/AErqV+j3o7rq+VYB1yxzy6afAr6+2fmhPjAY6vZ6zQ=";
  };
  patches = [ ./python.patch ];
  NIX_CFLAGS_LINK = "-cheerp-linear-heap-size=128";
  configureFlags = [
    "--without-ensurepip"
    "--disable-ipv6"
    "--disable-test-modules"
    "--with-build-python=${buildPackages.python312}/bin/python"
    "ac_cv_file__dev_ptmx=no"
    "ac_cv_file__dev_ptc=no"
    "ac_cv_func_dlopen=no"
  ];

  nativeBuildInputs = [ ];
}
