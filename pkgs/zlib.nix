{ stdenv
, fetchFromGitHub
}:
stdenv.mkDerivation rec {
  pname = "zlib";
  version = "1.2.8";

  src = fetchFromGitHub {
    owner = "madler";
    repo = "zlib";
    rev = "v${version}";
    sha256 = "sha256-4wO7E68VzDSP3yRthGmxkY0fDjwkCLK4Wp8bkIdtRU0=";
  };

  env.CHOST = stdenv.hostPlatform.config;
  configureFlags = [ "--static" ];
  configurePlatforms = [ ];
  dontDisableStatic = true;
  dontAddStaticConfigureFlags = true;
}
