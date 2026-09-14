# OpenDarwin Nixpkgs (Modern by-name package auto-discovery)
{ system ? builtins.currentSystem }:

let
  bootstrapStdenv = import ./stdenv { inherit system; }; 
  lib = {
    inherit (builtins) concatStringsSep replaceStrings elem foldl';
    unique = list:
      let
        fold = acc: elem:
          if builtins.elem elem acc then acc else acc ++ [ elem ];
      in
        builtins.foldl' fold [] list;
  };
in
let
  pkgs = autoPackages // rec {
    inherit system lib;

    # Bootstrap mold with a stdenv that does not itself require mold.  The
    # normal stdenv then makes mold a native input of every derivation.
    stdenv = import ./stdenv {
      inherit system;
      defaultNativeBuildInputs = [ mold-macho ];
      defaultUseMold = true;
    };
    inherit (builtins) fetchurl fetchTarball;

    callPackage = fn: overrides:
      let
        f = if builtins.isFunction fn then fn else import fn;
        args = if builtins ? functionArgs then
          builtins.intersectAttrs (builtins.functionArgs f) pkgs
        else pkgs;
      in
      f (args // overrides);

    # Rust and mold are bootstrap packages, built before the mold-enabled
    # stdenv is used for the rest of the package set.
    rust-bin = callPackage ./by-name/ru/rust-bin/package.nix {
      stdenv = bootstrapStdenv;
    };
    bootstrapCrane = import ./build-support/crane {
      inherit lib fetchurl;
      stdenv = bootstrapStdenv;
      rust-bin = rust-bin;
    };
    mold-macho = callPackage ./by-name/mo/mold-macho/package.nix {
      stdenv = bootstrapStdenv;
      craneLib = bootstrapCrane;
    };

    # Crane Rust build support for regular packages.
    crane = import ./build-support/crane { inherit lib stdenv fetchurl; rust-bin = pkgs.rust-bin; };
    craneLib = crane;

    # Aliases
    make = pkgs.gnumake;


  };

  # Auto-discover all packages in pkgs/by-name/<prefix>/<name>/package.nix
  byNameDir = ./by-name;
  prefixes = builtins.attrNames (builtins.readDir byNameDir);

  autoPackages = builtins.listToAttrs (
    builtins.concatLists (
      builtins.map (prefix:
        let
          prefixPath = byNameDir + "/${prefix}";
          entries = builtins.readDir prefixPath;
          pkgNames = builtins.attrNames entries;
        in
        builtins.map (name: {
          inherit name;
          value = pkgs.callPackage (prefixPath + "/${name}/package.nix") { };
        }) pkgNames
      ) prefixes
    )
  );
in
pkgs
