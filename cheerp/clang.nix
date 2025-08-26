{ lib
, stdenv
, cmake
, llvmPackages
, ninja
, python3
, libxml2
, libffi
, ncurses
, zlib
, zstd
, which
, filterSrc
, sources
, conf
, cheerp-llvm
}:
let
  build-type = if conf.build == "prod" then "Release" else "Debug";
  doCheck = conf.doCheck;
  cmakeListToString = l: lib.concatStringsSep ";" l;
  cmakeList = name: val: lib.cmakeOptionType "list" name (cmakeListToString val);
  distribution-components = [
    "clang"
    "clang-resource-headers"
  ];
in
stdenv.mkDerivation {
  pname = "cheerp-clang";
  version = "${conf.build}-master";

  inherit doCheck;

  src = filterSrc {
    root = sources.cheerp-compiler;
    include = [ "llvm/utils" "llvm/lib/Testing" "clang" "cmake" "third-party" ];
    exclude =
      if !doCheck then [
        "clang/test"
        "clang/unittests"
      ] else
        [ ];
  };

  sourceRoot = "source/clang";

  nativeBuildInputs =
    [ cmake ninja python3 llvmPackages.bintools cheerp-llvm ];
  buildInputs = [ libxml2 libffi ];
  propagatedBuildInputs = [ ncurses zlib zstd ];
  nativeCheckInputs = [ which ];

  postPatch =
    if doCheck then ''
      #remove some tests that don't work in a nix build. taken from nixpkgs
      rm test/Modules/header-attribs.cpp
    '' else
      "";

  cmakeBuildType = build-type;
  # workaround for option values with spaces
  preConfigure = ''
    cmakeFlagsArray+=(
      "-DCMAKE_CXX_FLAGS='-Wno-gnu-line-marker -Wno-deprecated-declarations'"
      "-DCMAKE_C_FLAGS_RELEASE='-O2 -DNDEBUG'"
      "-DCMAKE_CXX_FLAGS_RELEASE='-O2 -DNDEBUG'"
    )
  '';
  cmakeFlags = [
    "-GNinja"
    (lib.cmakeBool "CMAKE_COLOR_DIAGNOSTICS" true)
    (lib.cmakeBool "CMAKE_EXPORT_COMPILE_COMMANDS" true)
    (lib.cmakeFeature "CMAKE_C_FLAGS" "-Wno-gnu-line-marker")
    (lib.cmakeFeature "CMAKE_C_FLAGS_DEBUG" "-O2")
    (lib.cmakeFeature "CMAKE_CXX_FLAGS_DEBUG" "-O2")
    (lib.cmakeFeature "CMAKE_EXE_LINKER_FLAGS" "-fuse-ld=lld")
    (lib.cmakeFeature "CMAKE_SHARED_LINKER_FLAGS" "-fuse-ld=lld")
    (lib.cmakeFeature "CMAKE_MODULE_LINKER_FLAGS" "-fuse-ld=lld")
    (lib.cmakeFeature "LLVM_DIR" "${cheerp-llvm.dev}/lib/cmake/llvm")
    (lib.cmakeFeature "LLVM_TABLEGEN_EXE" "${cheerp-llvm.dev}/bin/llvm-tblgen")
    (lib.cmakeBool "LLVM_USE_RELATIVE_PATHS_IN_DEBUG_INFO" true)
    (lib.cmakeBool "LLVM_USE_RELATIVE_PATHS_IN_FILES" true)
    (lib.cmakeBool "LLVM_INCLUDE_TESTS" doCheck)
    (lib.cmakeBool "LLVM_ENABLE_PIC" false)
    (cmakeList "LLVM_DISTRIBUTION_COMPONENTS" distribution-components)
    (lib.cmakeBool "CLANG_ENABLE_STATIC_ANALYZER" false)
    (lib.cmakeBool "CLANG_ENABLE_ARCMT" false)
  ];
  buildPhase = ''
    TERM=dumb ninja -j$NIX_BUILD_CORES clang
  '';
  checkTarget = "check-clang";
  installTargets = [
    "install-distribution"
  ];

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
