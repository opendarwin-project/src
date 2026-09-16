# OpenDarwin standard environment (stdenv)
{ system ? builtins.currentSystem, defaultNativeBuildInputs ? [ ], defaultUseMold ? false }:

rec {
  inherit system;

  mkDerivation = attrs:
    let
      pname = attrs.pname or (if attrs ? name then attrs.name else "unnamed");
      version = attrs.version or "1.0";
      name = if attrs ? name then attrs.name else "${pname}-${version}";

      # Extract build input store paths
      buildInputs = attrs.buildInputs or [ ];
      nativeBuildInputs = defaultNativeBuildInputs ++ (attrs.nativeBuildInputs or [ ]);
      propagatedBuildInputs = attrs.propagatedBuildInputs or [ ];

      inputDrvs = buildInputs ++ nativeBuildInputs ++ propagatedBuildInputs;
      # The final stdenv supplies mold-macho as a native input. Bootstrap
      # stdenv has this disabled, avoiding a dependency cycle while building it.
      useMold = attrs.useMold or defaultUseMold;
      linkerFlags = if useMold then "-fuse-ld=mold" else "";

      # Toolchain bootstrap prologue.  Prepended to user-supplied
      # buildCommands so that (a) build inputs land on PATH/LIBRARY_PATH and (b)
      # the mold linker is the default `ld`/`clang` driver.  It cannot live in
      # defaultBuildCommand because most packages override buildCommand.
      toolchainSetup = ''
        # Setup build inputs and search paths
        for input in ''${nativeBuildInputs:-}; do
          if [ -d "$input/bin" ]; then
            export PATH="$input/bin:$PATH"
          fi
        done
        for input in ''${buildInputs:-}; do
          if [ -d "$input/bin" ]; then
            export PATH="$input/bin:$PATH"
          fi
          if [ -d "$input/lib" ]; then
            export LIBRARY_PATH="''${LIBRARY_PATH:-}''${LIBRARY_PATH:+:}$input/lib"
          fi
          if [ -d "$input/include" ]; then
            export CPATH="''${CPATH:-}''${CPATH:+:}$input/include"
          fi
        done

        ${moldSetup}
      '';

      # Create mold-backed clang/ld wrappers in the build directory and make
      # them the default toolchain.  `-B<mold-bin>` makes clang resolve `ld` to
      # mold; `-fuse-ld=mold` covers drivers that consult the flag instead.
      moldSetup = ''
        mkdir -p .toolchain-bin
        MOLD_BIN=""
        for input in ''${nativeBuildInputs:-}; do
          if [ -x "$input/bin/mold" ]; then
            MOLD_BIN="$input/bin"
            break
          fi
        done

        if [ -n "$MOLD_BIN" ]; then
          HOST_CLANG="$(command -v clang || echo /usr/bin/clang)"
          HOST_CLANGXX="$(command -v clang++ || echo /usr/bin/clang++)"

          cat << EOF > .toolchain-bin/ld
#!/bin/sh
exec "$MOLD_BIN/mold" "\$@"
EOF
          cat << EOF > .toolchain-bin/ld64
#!/bin/sh
exec "$MOLD_BIN/mold" "\$@"
EOF
          cat << EOF > .toolchain-bin/clang
#!/bin/sh
exec "$HOST_CLANG" -B"$MOLD_BIN" -fuse-ld=mold "\$@"
EOF
          cat << EOF > .toolchain-bin/clang++
#!/bin/sh
exec "$HOST_CLANGXX" -B"$MOLD_BIN" -fuse-ld=mold "\$@"
EOF
          cat << EOF > .toolchain-bin/cc
#!/bin/sh
exec "$HOST_CLANG" -B"$MOLD_BIN" -fuse-ld=mold "\$@"
EOF
          cat << EOF > .toolchain-bin/c++
#!/bin/sh
exec "$HOST_CLANGXX" -B"$MOLD_BIN" -fuse-ld=mold "\$@"
EOF
          cat << EOF > .toolchain-bin/gcc
#!/bin/sh
exec "$HOST_CLANG" -B"$MOLD_BIN" -fuse-ld=mold "\$@"
EOF
          cat << EOF > .toolchain-bin/g++
#!/bin/sh
exec "$HOST_CLANGXX" -B"$MOLD_BIN" -fuse-ld=mold "\$@"
EOF
          chmod +x .toolchain-bin/*
          export PATH="$(pwd)/.toolchain-bin:$PATH"
          export CC="$(pwd)/.toolchain-bin/cc"
          export CXX="$(pwd)/.toolchain-bin/c++"
          export LD="$(pwd)/.toolchain-bin/ld"
          export LDFLAGS="''${LDFLAGS:-} -fuse-ld=mold"
        fi
      '';

      # Default phase runner script when buildCommand is not provided
      defaultBuildCommand = ''
        set -euo pipefail

        # Setup build inputs and search paths
        for input in ''${nativeBuildInputs:-}; do
          if [ -d "$input/bin" ]; then
            export PATH="$input/bin:$PATH"
          fi
        done
        for input in ''${buildInputs:-}; do
          if [ -d "$input/bin" ]; then
            export PATH="$input/bin:$PATH"
          fi
          if [ -d "$input/lib" ]; then
            export LIBRARY_PATH="''${LIBRARY_PATH:-}''${LIBRARY_PATH:+:}$input/lib"
          fi
          if [ -d "$input/include" ]; then
            export CPATH="''${CPATH:-}''${CPATH:+:}$input/include"
          fi
        done

        # Unpack phase
        if [ -n "''${unpackPhase:-}" ]; then
          eval "$unpackPhase"
        elif [ -n "''${src:-}" ]; then
          if [ -d "$src" ]; then
            cp -R "$src"/. .
            chmod -R u+w .
          elif echo "$src" | grep -qE '\.tar\.(gz|xz|bz2|zst)$|\.tgz$'; then
            tar -xf "$src" --strip-components=1 2>/dev/null || tar -xf "$src"
          fi
        fi

        # Patch phase
        if [ -n "''${patchPhase:-}" ]; then
          eval "$patchPhase"
        elif [ -n "''${patches:-}" ]; then
          for p in $patches; do
            patch -p1 -i "$p"
          done
        fi

        # Configure phase
        if [ -n "''${configurePhase:-}" ]; then
          eval "$configurePhase"
        elif [ -z "''${dontConfigure:-}" ]; then
          if [ -f CMakeLists.txt ] && command -v cmake >/dev/null 2>&1; then
            cmake -B build -S . -DCMAKE_INSTALL_PREFIX="$out" ''${cmakeFlags:-}
          elif [ -x ./configure ]; then
            ./configure --prefix="$out" ''${configureFlags:-}
          fi
        fi

        # Build phase
        if [ -n "''${buildPhase:-}" ]; then
          eval "$buildPhase"
        elif [ -z "''${dontBuild:-}" ]; then
          NCPUS=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
          if [ -d build ] && [ -f build/build.ninja ]; then
            ninja -C build -j"$NCPUS"
          elif [ -d build ] && [ -f build/Makefile ]; then
            make -C build -j"$NCPUS"
          elif [ -f Makefile ] || [ -f makefile ]; then
            make -j"$NCPUS"
          fi
        fi

        # Install phase
        if [ -n "''${installPhase:-}" ]; then
          eval "$installPhase"
        elif [ -z "''${dontInstall:-}" ]; then
          mkdir -p "$out"
          if [ -d build ] && [ -f build/build.ninja ]; then
            ninja -C build install
          elif [ -d build ] && [ -f build/Makefile ]; then
            make -C build install prefix="$out"
          elif [ -f Makefile ] || [ -f makefile ]; then
            make install prefix="$out"
          fi
        fi

        # Fixup phase
        if [ -n "''${fixupPhase:-}" ]; then
          eval "$fixupPhase"
        fi
      '';

      userBuildCommand = attrs.buildCommand or defaultBuildCommand;
      # Only wrap when we actually inject the mold toolchain; this keeps the
      # bootstrap derivations (rust, crane, mold itself) on the plain path.
      buildCommand = if useMold then ''
        set -euo pipefail
        ${toolchainSetup}
        ${userBuildCommand}
      '' else userBuildCommand;

      # Default builders and standard arguments
      builder = attrs.builder or "/bin/sh";
      args = attrs.args or [ "-e" "-c" buildCommand ];

      # Clean attributes not meant to be passed to the derivation primitive
      cleanAttrs = builtins.removeAttrs attrs [
        "meta"
        "passthru"
        "builder"
        "args"
        "buildInputs"
        "nativeBuildInputs"
        "propagatedBuildInputs"
        "useMold"
      ];
    in
    (derivation (cleanAttrs // {
      inherit name pname version system builder args;
      NIX_LDFLAGS = attrs.NIX_LDFLAGS or linkerFlags;
      buildInputs = buildInputs;
      nativeBuildInputs = nativeBuildInputs;
      propagatedBuildInputs = propagatedBuildInputs;
    })) // {
      meta = attrs.meta or { };
      passthru = attrs.passthru or { };
    } // (attrs.passthru or { });
}

