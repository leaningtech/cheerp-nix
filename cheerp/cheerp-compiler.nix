{ lib, stdenv, cmake, llvmPackages, ninja, python3, libxml2, libffi, ncurses
, zlib, zstd, which, libedit, filterSrc, sources, conf, buildClangd ? false }:
let
  build-type = if conf.build == "prod" then "Release" else "Debug";
  doCheck = conf.doCheck && !buildClangd;
  cmakeListToString = l: lib.concatStringsSep ";" l;
  cmakeList = name: val: lib.cmakeOptionType "list" name (cmakeListToString val);
  llvm-projects = [
    "clang"
  ] ++ (if buildClangd then [ "clang-tools-extra" ] else []);
  toolchain-tools = [
    "llvm-dis"
    "llvm-ar"
    "llvm-link"
    "opt"
    "llc"
  ];
  distribution-components = toolchain-tools ++ [
    "clang"
    "clang-resource-headers"
  ] ++ (if buildClangd then [ "clangd" ] else []);
  targets = [
    "X86"
    "WebAssembly"
  ];
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

  cmakeBuildType = build-type;
  # workaround for option values with spaces
  preConfigure = ''
    cmakeFlagsArray+=(
      "-DCMAKE_CXX_FLAGS='-Wno-gnu-line-marker -Wno-deprecated-declarations'"
      "-DCMAKE_C_FLAGS_RELEASE='-O2 -DNDEBUG'"
      "-DCMAKE_CXX_FLAGS_RELEASE='-O2 -DNDEBUG'"
    )
    cd llvm
  '';
  cmakeFlags = [
    "-GNinja"
    (cmakeList "LLVM_ENABLE_PROJECTS" llvm-projects)
    (lib.cmakeBool "CMAKE_COLOR_DIAGNOSTICS" true)
    (lib.cmakeBool "CMAKE_EXPORT_COMPILE_COMMANDS" true)
    (lib.cmakeFeature "CMAKE_C_FLAGS" "-Wno-gnu-line-marker")
    (lib.cmakeFeature "CMAKE_C_FLAGS_DEBUG" "-02")
    (lib.cmakeFeature "CMAKE_CXX_FLAGS_DEBUG" "-02")
    (lib.cmakeFeature "CMAKE_EXE_LINKER_FLAGS" "-fuse-ld=lld")
    (lib.cmakeFeature "CMAKE_SHARED_LINKER_FLAGS" "-fuse-ld=lld")
    (lib.cmakeFeature "CMAKE_MODULE_LINKER_FLAGS" "-fuse-ld=lld")
    (lib.cmakeBool "LLVM_USE_RELATIVE_PATHS_IN_DEBUG_INFO" true)
    (lib.cmakeBool "LLVM_USE_RELATIVE_PATHS_IN_FILES" true)
    (lib.cmakeBool "LLVM_INCLUDE_TESTS" doCheck)
    (lib.cmakeFeature "LLVM_DEFAULT_TARGET_TRIPLE" "cheerp-leaningtech-webbrowser-wasm")
    (lib.cmakeBool "LLVM_INSTALL_TOOLCHAIN_ONLY" true)
    (cmakeList "LLVM_TARGETS_TO_BUILD" targets)
    (cmakeList "LLVM_TOOLCHAIN_TOOLS" toolchain-tools)
    (cmakeList "LLVM_DISTRIBUTION_COMPONENTS" distribution-components)
    (lib.cmakeBool "CLANG_ENABLE_STATIC_ANALYZER" false)
    (lib.cmakeBool "CLANG_ENABLE_ARCMT" false)
  ];
  buildPhase = ''
    TERM=dumb ninja -j$NIX_BUILD_CORES ${if buildClangd then "clangd" else "distribution"}
  '';
  checkPhase = ''
    TERM=dumb ninja -j$NIX_BUILD_CORES check-llvm
    TERM=dumb ninja -j$NIX_BUILD_CORES check-clang
  '';
  installTargets = [
    (if buildClangd then "install-clangd" else "install-distribution")
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
