{ lib
, stdenv
, buildPackages
, fetchurl
, pkg-config
, texinfo
}:

stdenv.mkDerivation rec {
  pname = "e2fsprogs";
  version = "1.47.2";

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/people/tytso/e2fsprogs/v${version}/e2fsprogs-${version}.tar.xz";
    hash = "sha256-CCQuZMoOgZTZwcqtSXYrGSCaBjGBmbY850rk7y105jw=";
  };

  # fuse2fs adds 14mb of dependencies
  outputs = [
    "bin"
    "dev"
    "out"
    "man"
    "info"
  ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [
    pkg-config
    texinfo
  ];
  buildInputs = [
  ];

  configureFlags = [
    "--disable-elf-shlibs"
    "--enable-symlink-install"
    "--enable-relative-symlinks"
    "--with-crond-dir=no"
    "--disable-fsck"
    "--disable-uuidd"
    "--enable-libuuid"
    "--enable-libblkid"
    "--disable-debugfs"
    "--disable-resizer"
    "--disable-defrag"
    "--disable-tls"
    "--disable-fuse2fs"
  ];
  env.ac_cv_func_chflags = "no";

  doCheck = false;

  postInstall = ''
    # avoid cycle between outputs
    if [ -f $out/lib/${pname}/e2scrub_all_cron ]; then
      mv $out/lib/${pname}/e2scrub_all_cron $bin/bin/
    fi
  '';
}
