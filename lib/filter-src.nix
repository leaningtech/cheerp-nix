{ lib, nix-filter }: (
  { root, include ? null, exclude ? [ ] }:
  if builtins.isPath root then
    let
      makePaths = l:
        map (p: fs.maybeMissing (root + "/${p}")) l;
      fs = lib.fileset;
    in
    fs.toSource {
      root = root;
      fileset =
        if include != null then
          fs.difference (fs.unions (makePaths include)) (fs.unions (makePaths exclude))
        else
          fs.difference root (fs.unions (makePaths exclude));
    }
  else
    if include != null then
      nix-filter
      {
        inherit root include exclude;
      }
    else
      nix-filter { inherit root exclude; }
)
