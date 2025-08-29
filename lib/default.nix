{ lib, pkgs, runCommand, callPackage }: {
  filterSrc = callPackage ./filter-src.nix { };
  env = import ./env.nix;
  overridableSources = sources:
    builtins.mapAttrs
      (name: path:
        let
          name' = if name == "nixpkgs" then "nixpkgs'" else name;
          override = builtins.tryEval (builtins.findFile builtins.nixPath name');
        in
        if override.success then
          (builtins.trace "OVERRIDING input ${name'} from NIX_PATH " override.value)
        else
          (path { inherit pkgs; })
      )
      sources;
}
