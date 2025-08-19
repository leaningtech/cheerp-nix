{ lib
, runCommand
, jq
, python3
, packages
}:
let
  collect-direct-deps = attrs: runCommand "collect-direct-deps"
    rec {
      __structuredAttrs = true;
      exportReferencesGraph = lib.mapAttrs'
        (name: val:
          lib.nameValuePair "graph-${name}" val.drvPath
        )
        attrs;
      names = builtins.attrNames attrs;
      paths = builtins.attrValues attrs;
      drvs = map (p: p.drvPath) paths;
      nativeBuildInputs = [ jq ];
    } ''
    for i in "''${!names[@]}"; do
      deps=("''${drvs[@]:0:$i}" "''${drvs}[@]:$((i+1))")
      jq ".\"graph-''${names[$i]}\" | [.[] | select(.path | IN(\$ARGS.positional[])) | .path] | {\"''${names[$i]}\": {deps:., drv:\"''${drvs[$i]}\"}}" "$NIX_ATTRS_JSON_FILE" --args "''${deps[@]}" > "$i.json"
    done
    jq --slurp 'add' *.json > $out
  '';

  make-config = attrs:
    let
      deps = collect-direct-deps attrs;
    in
    runCommand "config"
      {
        nativeBuildInputs = [ python3 ];
      } ''
      python3 ${./generate-config.py} ${deps} > $out
    '';
  release = import ../release.nix packages;
  releaseOnlyDrvs = (lib.filterAttrs (name: value: value? drvPath) release);
in
{
  inherit release;
  config = make-config release;
}
