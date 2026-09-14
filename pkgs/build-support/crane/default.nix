{ lib ? {}, stdenv, fetchurl, rust-bin ? null }:

# Crane-style Cargo -> Nix build support.
#
# Mirrors the architecture of https://github.com/ipetkov/crane:
#
#   * `vendorCargoDeps` materialises every locked crate into a single
#     `cargo-vendor-dir` output (registry crates are fetched one-by-one as
#     fixed-output derivations; git crates are checked out at their locked rev).
#
#   * `buildDepsOnly` compiles *only* the dependency graph, using a dummy copy
#     of the source tree whose crates are stubbed out, and installs the resulting
#     cargo `target/` directory as its output (`cargoArtifacts`).
#
#   * `cargoBuild` starts from those prebuilt artifacts and compiles the real
#     sources. Because the dependency compilation lives in a *different*
#     derivation, it is cached independently and only needs to happen once.
#
#   * `buildPackage` is the convenience wrapper:
#       cargoBuild { cargoArtifacts = buildDepsOnly args; } // args
#
# Splitting the build this way is what gives Crane its incremental rustc builds.

let
  # Materialise a vendored-dependency directory and point cargo at it.
  configureVendoredDeps = vendorDir: ''
    mkdir -p .cargo
    cp -R ${vendorDir}/vendor ./vendor
    cp ${vendorDir}/.cargo/config.toml .cargo/config.toml
  '';

  cargoToolchain = if rust-bin != null then [ rust-bin ] else [];
in
rec {
  # Resolve the vendored dependency directory for a build, if any.
  resolveVendorDir = { cargoLock ? null, cargoVendorDir ? null }:
    if cargoVendorDir != null then cargoVendorDir
    else if cargoLock != null then vendorCargoDeps { inherit cargoLock; }
    else null;
  # Download an individual crate from crates.io
  downloadCargoPackage = { name, version, checksum ? null, sha256 ? null }:
    fetchurl {
      url = "https://static.crates.io/crates/${name}/${name}-${version}.crate";
      sha256 = if checksum != null then checksum else sha256;
    };

  # Vendor cargo dependencies from a Cargo.lock file
  vendorCargoDeps = { cargoLock ? null, cargoLockContents ? null, packages ? [] }:
    let
      lockData =
        if cargoLock != null then
          (if builtins ? importCargoLock then builtins.importCargoLock cargoLock
           else builtins.fromTOML (builtins.readFile cargoLock))
        else if cargoLockContents != null then
          builtins.fromTOML cargoLockContents
        else { package = packages; };

      pkgsList = lockData.packages or (lockData.package or []);

      vendorCrate = pkg:
        let
          isCratesIo = (pkg.source or "") == "registry+https://github.com/rust-lang/crates.io-index" || (pkg ? checksum);
          isGit = builtins.substring 0 4 (pkg.source or "") == "git+";
        in
          if isCratesIo && (pkg ? checksum) then
            let
              crateSrc = downloadCargoPackage {
                name = pkg.name;
                version = pkg.version;
                checksum = pkg.checksum;
              };
              crateDir = "${pkg.name}-${pkg.version}";
            in ''
              mkdir -p $out/vendor/${crateDir}
              tar -xzf ${crateSrc} -C $out/vendor/${crateDir} --strip-components=1
              echo '{"package":"${pkg.checksum}","files":{}}' > $out/vendor/${crateDir}/.cargo-checksum.json
            ''
          else if isGit then
            let
              rawGitUrl = pkg.git or (builtins.replaceStrings ["git+"] [""] (pkg.source or ""));
              rev = pkg.rev or "HEAD";
              gitArchiveUrl = pkg.gitArchiveUrl or "${rawGitUrl}/archive/${rev}.tar.gz";
              crateDir = "${pkg.name}-${pkg.version}";
            in ''
              mkdir -p $out/vendor/${crateDir}
              mkdir -p $out/vendor/${pkg.name}
              mkdir -p "$TMPDIR/git_${pkg.name}"
              if command -v git >/dev/null 2>&1; then
                git clone "${rawGitUrl}" "$TMPDIR/git_${pkg.name}" 2>/dev/null || true
                if [ -d "$TMPDIR/git_${pkg.name}/.git" ]; then
                  ( cd "$TMPDIR/git_${pkg.name}" && git checkout "${rev}" 2>/dev/null || true )
                  ( cd "$TMPDIR/git_${pkg.name}" && git submodule update --init --recursive 2>/dev/null || true )
                fi
              fi
              if [ ! -d "$TMPDIR/git_${pkg.name}/.git" ]; then
                curl -sL "${gitArchiveUrl}" | tar -xz -C "$TMPDIR/git_${pkg.name}" --strip-components=1 2>/dev/null || true
              fi
              if [ -d "$TMPDIR/git_${pkg.name}/${pkg.name}" ]; then
                cp -r "$TMPDIR/git_${pkg.name}/${pkg.name}/"* $out/vendor/${crateDir}/ 2>/dev/null || true
                cp -r "$TMPDIR/git_${pkg.name}/${pkg.name}/"* $out/vendor/${pkg.name}/ 2>/dev/null || true
              else
                cp -r "$TMPDIR/git_${pkg.name}/"* $out/vendor/${crateDir}/ 2>/dev/null || true
                cp -r "$TMPDIR/git_${pkg.name}/"* $out/vendor/${pkg.name}/ 2>/dev/null || true
              fi
              echo '{"package":null,"files":{}}' > $out/vendor/${crateDir}/.cargo-checksum.json
              echo '{"package":null,"files":{}}' > $out/vendor/${pkg.name}/.cargo-checksum.json
            ''
          else "";

      vendorCommands = builtins.concatStringsSep "\n" (map vendorCrate pkgsList);

      gitPkgs = builtins.filter (p: builtins.substring 0 4 (p.source or "") == "git+") pkgsList;
      uniqueGitSources = lib.unique (map (p: p.source or "") gitPkgs);

      gitSourceConfig = builtins.concatStringsSep "\n" (map (source:
        let
          pkg = builtins.head (builtins.filter (p: (p.source or "") == source) gitPkgs);
          gitUrl = pkg.git or (builtins.replaceStrings ["git+"] [""] source);
          rev = pkg.rev or "";
          # Cargo source keys never include the `#<precise>` fragment
          cleanKey = builtins.head (builtins.split "#" source);
        in ''
          [source."${cleanKey}"]
          git = "${gitUrl}"
          ${if rev != "" then "rev = \"${rev}\"" else ""}
          replace-with = "vendored-sources"
        ''
      ) uniqueGitSources);
    in
      stdenv.mkDerivation {
        name = "cargo-vendor-dir";

        buildCommand = ''
          mkdir -p $out/vendor
          mkdir -p $out/.cargo

          ${vendorCommands}

          cat << 'EOF' > $out/.cargo/config.toml
          [source.crates-io]
          replace-with = "vendored-sources"

          ${gitSourceConfig}

          [source.vendored-sources]
          directory = "vendor"
          EOF
        '';
      };

  # Produce a "dummy" copy of a crate's source tree: every Rust file is replaced
  # with a trivial stub and every target definition ([lib], [[bin]], [[test]],
  # ...) is stripped from each Cargo.toml. The dependency graph (Cargo.lock,
  # [dependencies], [features], [workspace], [patch], .cargo/config.toml) is
  # preserved so `cargo` still resolves and compiles every dependency.
  mkDummySrc = { src, name ? "dummy-src" }:
    stdenv.mkDerivation {
      inherit name;

      buildCommand = ''
        set -e
        mkdir -p "$out"

        # Unpack the provided source (tarball or directory) into $out
        if [ -d "${src}" ]; then
          cp -R "${src}"/. "$out"/
        elif [ -f "${src}" ]; then
          if tar -tf "${src}" >/dev/null 2>&1; then
            tar -xf "${src}" -C "$out" --strip-components=1 2>/dev/null || tar -xf "${src}" -C "$out"
          fi
        fi
        chmod -R u+w "$out"
        cd "$out"

        # Stub out all Rust sources. `main.rs` / `src/bin/*` need a `main` fn so
        # the stub still links; everything else can be empty.
        find . -name '*.rs' -type f | while read -r f; do
          case "$f" in
            */build.rs|*/main.rs|*/bin/*) printf 'fn main() {}\n' > "$f" ;;
            *) : > "$f" ;;
          esac
        done

        # Strip target-defining tables so cargo falls back to the default source
        # locations that we just stubbed.
        find . -name Cargo.toml -type f | while read -r f; do
          awk '
            /^[[:space:]]*\[\[(bin|example|bench|test)\]\]/ { skip = 1; next }
            /^[[:space:]]*\[lib\]/ { skip = 1; next }
            /^[[:space:]]*\[/ { skip = 0 }
            { if (!skip) print }
          ' "$f" > "$f.clean"
          mv "$f.clean" "$f"
        done

        # Drop sources that are not needed for dependency compilation
        find . -type d \( -name .git -o -name target \) -prune -exec rm -rf {} + 2>/dev/null || true
      '';
    };

  # Compile only the dependency graph and return the resulting cargo `target/`
  # directory as `cargoArtifacts`, ready to be fed into `cargoBuild`.
  buildDepsOnly = {
    pname,
    version,
    src,
    cargoLock ? null,
    cargoVendorDir ? null,
    cargoBuildFlags ? "--release",
    cargoCheckFlags ? "--all-targets",
    cargoTestFlags ? "--no-run",
    doCheck ? true,
    nativeBuildInputs ? [],
    buildInputs ? [],
    ...
  }@args:
    let
      vendorDir = resolveVendorDir { inherit cargoLock cargoVendorDir; };
      dummySrc = mkDummySrc { inherit src; name = "${pname}-${version}-dummy-src"; };
    in
      stdenv.mkDerivation {
        name = "${pname}-${version}-deps";
        src = dummySrc;

        nativeBuildInputs = cargoToolchain ++ nativeBuildInputs ++ (if vendorDir != null then [ vendorDir ] else []);
        inherit buildInputs;

        # `src` is a directory of dummy sources rather than an archive.
        unpackPhase = ''
          cp -R ${dummySrc}/. .
          chmod -R u+w .
        '';

        configurePhase =
          if vendorDir != null then configureVendoredDeps vendorDir else ":";

        buildPhase = ''
          export CARGO_HOME=$PWD/.cargo
          echo "compiling dependencies"
          cargo check ${cargoCheckFlags} --offline
          cargo build ${cargoBuildFlags} --offline
          ${if doCheck then "cargo test ${cargoTestFlags} --offline" else ""}
        '';

        installPhase = ''
          mkdir -p $out
          cp -R target $out/target
        '';
      };

  # Build the real crate, reusing the dependency artifacts produced by
  # `buildDepsOnly`.
  cargoBuild = {
    pname,
    version,
    src,
    cargoArtifacts ? null,
    cargoLock ? null,
    cargoVendorDir ? null,
    cargoBuildFlags ? "--release",
    patches ? [],
    installPhase ? null,
    doCheck ? false,
    checkPhase ? null,
    nativeBuildInputs ? [],
    buildInputs ? [],
    ...
  }@args:
    let
      vendorDir = resolveVendorDir { inherit cargoLock cargoVendorDir; };

      inheritArtifacts =
        if cargoArtifacts != null then ''
          echo "reusing cargo artifacts from ${cargoArtifacts}"
          mkdir -p target
          cp -R ${cargoArtifacts}/target/. target/
          chmod -R u+w target
        '' else "";

      defaultInstall = ''
        mkdir -p $out/bin
        find target/release -maxdepth 1 -type f -perm +111 -exec cp {} $out/bin/ \;
      '';
    in
      stdenv.mkDerivation {
        name = "${pname}-${version}";
        inherit src patches buildInputs;
        meta = args.meta or {};

        nativeBuildInputs = cargoToolchain ++ nativeBuildInputs
          ++ (if vendorDir != null then [ vendorDir ] else [])
          ++ (if cargoArtifacts != null then [ cargoArtifacts ] else []);

        configurePhase = ''
          ${if vendorDir != null then configureVendoredDeps vendorDir else ""}
          ${inheritArtifacts}
        '';

        buildPhase = ''
          export CARGO_HOME=$PWD/.cargo
          cargo build ${cargoBuildFlags} --offline
        '';

        checkPhase =
          if checkPhase != null then checkPhase
          else if doCheck then "export CARGO_HOME=$PWD/.cargo; cargo test ${cargoBuildFlags} --offline"
          else ":";

        installPhase = if installPhase != null then installPhase else defaultInstall;
      };

  # Convenience wrapper: compile dependencies in their own derivation, then
  # build the package against them.
  buildPackage = args:
    let
      artifacts =
        if args ? cargoArtifacts && args.cargoArtifacts != null then args.cargoArtifacts
        else buildDepsOnly args;
    in
      cargoBuild (args // { cargoArtifacts = artifacts; });
}