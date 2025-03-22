{ lib, symlinkJoin, cheerp-compiler, cheerp-utils, libs, name ? "cheerp" }:
symlinkJoin {
  name = name;
  paths = [ cheerp-compiler cheerp-utils ] ++ libs;
  postBuild = ''
    rm $out/share/cmake/Modules/CheerpCommon.cmake;
    rm $out/share/cmake/Modules/CheerpToolchain.cmake;
    rm $out/share/cmake/Modules/CheerpWasmToolchain.cmake;
    substitute ${cheerp-utils}/share/cmake/Modules/CheerpCommon.cmake $out/share/cmake/Modules/CheerpCommon.cmake \
      --replace "${cheerp-compiler}" $out
    substitute ${cheerp-utils}/share/cmake/Modules/CheerpToolchain.cmake $out/share/cmake/Modules/CheerpToolchain.cmake \
      --replace "${cheerp-compiler}" $out
    substitute ${cheerp-utils}/share/cmake/Modules/CheerpWasmToolchain.cmake $out/share/cmake/Modules/CheerpWasmToolchain.cmake \
      --replace "${cheerp-compiler}" $out

    rm $out/bin/cheerpwrap
    substitute ${cheerp-utils}/bin/cheerpwrap $out/bin/cheerpwrap \
      --replace "${cheerp-compiler}" $out
    chmod a+x $out/bin/cheerpwrap
  '';
  meta.mainProgram = "clang++";
}
