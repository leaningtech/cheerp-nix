{ lib, stdenv, cmake, llvmPackages, ninja, python3, libxml2, libffi, ncurses
, zlib, zstd, which, libedit, filterSrc, sources, conf, buildClangd ? false }:
let
  build-type = if conf.build == "prod" then "Release" else "Debug";
  doCheck = conf.doCheck;
in stdenv.mkDerivation {
  pname = if buildClangd then "cheerp-clangd" else "cheerp-compiler";
  version = "${conf.build}-master";

  inherit doCheck;

  src = filterSrc {
    root = sources.cheerp-compiler;
    include = [ "clang" "llvm" "cmake" "third-party" ]
      ++ (if buildClangd then [ "clang-tools-extra" ] else [ ]);
    exclude = if !doCheck then [
      "llvm/test"
      "llvm/unittests"
      "clang/test"
      "clang/unittests"
    ] else
      [ ];
  };

  nativeBuildInputs =
    [ cmake ninja python3 llvmPackages.llvm llvmPackages.bintools ];
  buildInputs = [ libxml2 libffi ];
  propagatedBuildInputs = [ ncurses zlib zstd libedit ];
  nativeCheckInputs = [ which ];

  postPatch = if doCheck then ''
    #remove some tests that don't work in a nix build. taken from nixpkgs

    rm llvm/test/tools/llvm-objcopy/ELF/mirror-permissions-unix.test

    substituteInPlace llvm/unittests/Support/VirtualFileSystemTest.cpp \
      --replace "PhysicalFileSystemWorkingDirFailure" "DISABLED_PhysicalFileSystemWorkingDirFailure"

    substituteInPlace llvm/unittests/Support/CMakeLists.txt \
      --replace "Path.cpp" ""
    rm llvm/unittests/Support/Path.cpp

    rm clang/test/Modules/header-attribs.cpp
  '' else
    "";

  configurePhase = ''
    cmake \
    -DCMAKE_INSTALL_PREFIX=$out \
    -DLLVM_ENABLE_PROJECTS="clang${
      if buildClangd then ";clang-tools-extra" else ""
    }" \
    -GNinja \
    -DCMAKE_BUILD_TYPE=${build-type} \
    -DCMAKE_COLOR_DIAGNOSTICS=ON \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_C_FLAGS="-Wno-gnu-line-marker" \
    -DCMAKE_CXX_FLAGS="-Wno-gnu-line-marker" \
    -DCMAKE_C_FLAGS_RELEASE="-O2 -DNDEBUG" \
    -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG -Wno-deprecated-declarations" \
    -DCMAKE_C_FLAGS_DEBUG="-O2" \
    -DCMAKE_CXX_FLAGS_DEBUG="-O2 -Wno-deprecated-declarations" \
    -DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=lld \
    -DCMAKE_SHARED_LINKER_FLAGS=-fuse-ld=lld \
    -DCMAKE_MODULE_LINKER_FLAGS=-fuse-ld=lld \
    -DLLVM_USE_RELATIVE_PATHS_IN_DEBUG_INFO=ON \
    -DLLVM_USE_RELATIVE_PATHS_IN_FILES=ON \
    -DLLVM_INCLUDE_TESTS=${if doCheck then "ON" else "OFF"} \
    -C llvm/CheerpCmakeConf.cmake -B build -S llvm
    cd build
  '';
  buildPhase = ''
    ninja -j $NIX_BUILD_CORES ${if buildClangd then "clangd" else ""}
  '';
  checkPhase = ''
    ninja -j $NIX_BUILD_CORES check-llvm
    ninja -j $NIX_BUILD_CORES check-clang
  '';
  installPhase = ''
    ninja ${if buildClangd then "install-clangd" else "install-distribution"}
  '';

  meta = with lib; {
    homepage = "https://github.com/leaningtech/cheerp-compiler";
    description = ''
      A C++ compiler for the web";
    '';
    license = licenses.mit;
    platforms = with platforms; linux;
    maintainers = [ ];
  };
}
