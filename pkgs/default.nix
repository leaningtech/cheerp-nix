self: super:
let
  inherit (self) callPackage;
in
{
  zlib = callPackage ./zlib.nix {};
  freetype = callPackage ./freetype.nix {};
  expat = callPackage ./expat.nix {};
  icu = callPackage ./icu.nix {};
  xorgproto = callPackage ./xorgproto.nix {};
  harfbuzz = callPackage ./harfbuzz.nix {};
}
