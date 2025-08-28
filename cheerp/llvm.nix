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
}:
let
  build-type = if conf.build == "prod" then "Release" else "Debug";
  doCheck = conf.doCheck;
  cmakeListToString = l: lib.concatStringsSep ";" l;
  cmakeList = name: val: lib.cmakeOptionType "list" name (cmakeListToString val);
  toolchain-tools = [
    "llvm-config"
    "llvm-tblgen"
    "llvm-dis"
    "llvm-ar"
    "llvm-link"
    "opt"
    "llc"
  ];
  distribution-components = toolchain-tools ++ [
    "llvm-libraries"
    "llvm-headers"
    "cmake-exports"
  ];
  targets = [
    "X86"
    "WebAssembly"
  ];
in
stdenv.mkDerivation {
  pname = "cheerp-llvm";
  version = "${conf.build}-master";

  inherit doCheck;

  src = filterSrc {
    root = sources.cheerp-compiler;
    include = [ "llvm" "cmake" "third-party" ];
    exclude =
      if !doCheck then [
        "llvm/test"
        "llvm/unittests"
      ] else
        [ ];
  };
  sourceRoot = "source/llvm";

  nativeBuildInputs =
    [ cmake ninja python3 llvmPackages.llvm llvmPackages.bintools ];
  buildInputs = [ libxml2 libffi ];
  propagatedBuildInputs = [ ncurses zlib zstd ];
  nativeCheckInputs = [ which ];

  outputs = [
    "out"
    "dev"
  ];

  postPatch =
    if doCheck then ''
      #remove some tests that don't work in a nix build. taken from nixpkgs

      rm test/tools/llvm-objcopy/ELF/mirror-permissions-unix.test

      substituteInPlace unittests/Support/VirtualFileSystemTest.cpp \
        --replace "PhysicalFileSystemWorkingDirFailure" "DISABLED_PhysicalFileSystemWorkingDirFailure"

      substituteInPlace unittests/Support/CMakeLists.txt \
        --replace "Path.cpp" ""
      rm unittests/Support/Path.cpp
    '' else
      "";

  cmakeBuildType = build-type;
  # workaround for option values with spaces
  preConfigure = ''
    cmakeFlagsArray+=(
      -DCMAKE_CXX_FLAGS="-Wno-gnu-line-marker -Wno-deprecated-declarations"
      -DCMAKE_C_FLAGS_RELEASE="-O2 -DNDEBUG"
      -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG"
      -DLLVM_LIT_ARGS="--verbose -j''${NIX_BUILD_CORES}"
    )
  '';
  cmakeFlags = [
    "-GNinja"
    (cmakeList "LLVM_TARGETS_TO_BUILD" targets)
    (lib.cmakeBool "CMAKE_COLOR_DIAGNOSTICS" true)
    (lib.cmakeBool "CMAKE_EXPORT_COMPILE_COMMANDS" true)
    (lib.cmakeFeature "CMAKE_C_FLAGS" "-Wno-gnu-line-marker")
    (lib.cmakeFeature "CMAKE_C_FLAGS_DEBUG" "-O2")
    (lib.cmakeFeature "CMAKE_CXX_FLAGS_DEBUG" "-O2")
    (lib.cmakeFeature "CMAKE_EXE_LINKER_FLAGS" "-fuse-ld=lld")
    (lib.cmakeFeature "CMAKE_SHARED_LINKER_FLAGS" "-fuse-ld=lld")
    (lib.cmakeFeature "CMAKE_MODULE_LINKER_FLAGS" "-fuse-ld=lld")
    (lib.cmakeFeature "LLVM_INSTALL_PACKAGE_DIR" "${placeholder "out"}/lib/cmake/llvm")
    (lib.cmakeBool "LLVM_USE_RELATIVE_PATHS_IN_DEBUG_INFO" true)
    (lib.cmakeBool "LLVM_USE_RELATIVE_PATHS_IN_FILES" true)
    (lib.cmakeBool "LLVM_INCLUDE_TESTS" doCheck)
    (lib.cmakeBool "LLVM_INSTALL_UTILS" doCheck)
    (lib.cmakeBool "LLVM_ENABLE_PIC" false)
    (lib.cmakeBool "LLVM_ENABLE_LIBXML2" false)
    (lib.cmakeFeature "LLVM_DEFAULT_TARGET_TRIPLE" "cheerp-leaningtech-webbrowser-wasm")
    (cmakeList "LLVM_TOOLCHAIN_TOOLS" toolchain-tools)
    (cmakeList "LLVM_DISTRIBUTION_COMPONENTS" distribution-components)
  ];
  buildPhase = ''
    TERM=dumb ninja -j$NIX_BUILD_CORES distribution
  '';
  checkTarget = "check-llvm";
  installTargets = if doCheck then [
    "install"
  ] else [
    "install-distribution"
  ];
  postInstall = ''
    mkdir -p $dev
    mv $out/* $dev/
    substituteInPlace "$dev/lib/cmake/llvm/LLVMExports-${lib.toLower build-type}.cmake" \
      --replace-fail "$out" "$dev"
    substituteInPlace "$dev/lib/cmake/llvm/LLVMExports.cmake" \
      --replace-fail "$out" "$dev"
    substituteInPlace "$dev/lib/cmake/llvm/LLVMConfig.cmake" \
      --replace-fail "$out" "$dev"

    mkdir -p $out/bin
    mv $dev/bin/{llvm-dis,llvm-ar,llvm-link,opt,llc} $out/bin/
    ln -s $out/bin/{llvm-dis,llvm-ar,llvm-link,opt,llc} $dev/bin/
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
