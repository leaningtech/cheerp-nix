self: super:
let
  inherit (self) callPackage;
  xorgPkgs = {
    xorgproto = callPackage ./xorgproto.nix { };
    libXau = callPackage ./libXau.nix { };
    xcb-proto = callPackage ./xcb-proto.nix { };
    libxcb = callPackage ./libxcb.nix { };
    xtrans = callPackage ./xtrans.nix { };
    libX11 = callPackage ./libX11.nix { };
    libXext = callPackage ./libXext.nix { };
    libXxf86vm = callPackage ./libXxf86vm.nix { };
    libXrender = callPackage ./libXrender.nix { };
    libXrandr = callPackage ./libXrandr.nix { };
    libXfixes = callPackage ./libXfixes.nix { };
    libXcursor = callPackage ./libXcursor.nix { };
  };
  pkgs = {
    xorg = super.xorg // xorgPkgs;
    zlib = callPackage ./zlib.nix { };
    freetype = callPackage ./freetype.nix { };
    expat = callPackage ./expat.nix { };
    icu = callPackage ./icu.nix { };
    harfbuzz = callPackage ./harfbuzz.nix { };
    gl4es = callPackage ./gl4es.nix { };
  };
in
pkgs // {
  __buildSet = pkgs // { xorg = super.lib.recurseIntoAttrs xorgPkgs; };
}
