{ lib
, stdenv
, mkShell
, path
, bashInteractive
, coreutils
, git
, curl
, jq
, gnugrep
, findutils
, gnutar
, gzip
, xz
, which
, dockerTools
, nix
, packages
}:
let
  # Pre-included packages for CI
  basePackages = [
    nix
    bashInteractive
    coreutils
    git
    curl
    jq
    gnugrep
    findutils
    gnutar
    gzip
    xz
    which
  ];
  baseDeps = mkShell {
    name = "baseDeps";
    inputsFrom = [
      packages.cheerp-llvm
    ];
  };

  # Create a streaming image script
  streamImage = dockerTools.streamLayeredImage {
    name = "cheerp-nix-ci";
    tag = "latest";

    # Include Nix database for working nix-store commands
    includeStorePaths = true;

    contents = basePackages ++ [
      dockerTools.fakeNss       # Provides /etc/passwd and /etc/group
      dockerTools.caCertificates # Provides CA certificates
      dockerTools.usrBinEnv      # Provides /usr/bin/env
      dockerTools.binSh          # Provides /bin/sh
    ];

    # Extra commands run when building the image
    extraCommands = ''
      # Create Nix configuration
      mkdir -p etc/nix
      cat > etc/nix/nix.conf <<EOF
      experimental-features = nix-command flakes ca-derivations
      cores = 4
      max-jobs = 2
      sandbox = false
      sandbox-fallback = true
      system-features = nixos-test benchmark big-parallel kvm
      substituters = https://nix.leaningtech.com/cheerp https://cache.nixos.org/
      trusted-public-keys = cheerp:WtaH6hNyE1jx3KqrDkTqHfub4qEBhJWZwiIuPAPqF44= lt:990XBPGBQWHGyzpLno3a5vfWo5G8O+0qlxRmrvbOQVQ= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
      trusted-users = root
      EOF

      mkdir -p root
      mkdir -p tmp
      chmod 1777 tmp

    '';

    # Maximize layer sharing (modern Docker supports up to 128)
    maxLayers = 125;

    config = {
      Cmd = [ "${bashInteractive}/bin/bash" ];

      Env = [
        "__HACK=${baseDeps}"
        "NIX_PATH=nixpkgs=${path}"
        "PATH=${lib.makeBinPath basePackages}:/nix/var/nix/profiles/default/bin:/bin"
        "USER=root"
        "HOME=/root"
        "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
        "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
        "CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt"
        "GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt"
        "LANG=C.UTF-8"
        "LC_ALL=C.UTF-8"
      ];

      WorkingDir = "/root";
    };
  };

in
{
  docker = streamImage;
  release = import ../release.nix packages;
}
