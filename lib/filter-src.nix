{ lib, runCommand }: (
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
    let
      makePathArgs = list: builtins.concatStringsSep " -o " (map (p: "-path './${p}'") (list));
      includeArgs = makePathArgs include;
      excludeArgs = makePathArgs exclude;
    in
    runCommand "source"
    {
      __contentAddressed = false;
      preferLocalBuild = true;
    } ''
      mkdir -p $out
      ${if include != null then ''
        cd ${root}
        find . ${includeArgs} \( -type f -o -type d -o -type l \) | while read item; do
          mkdir -p "$out/$(dirname "$item")"
          cp -a --reflink=auto "$item" "$out/$item"
        done
      '' else ''
        cp -r ${root}/. $out/
      ''}
      ${if exclude != null && exclude != [] then ''
        chmod -R u+w $out
        cd $out
        find . \( -type f -o -type d -o -type l \) \( ${excludeArgs} \) -exec rm -r {} +
        find . -type d -empty -delete
        chmod -R u-w $out
      '' else ''
      ''}
    ''
)

