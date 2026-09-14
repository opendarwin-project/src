{ lib, stdenv, fetchurl, craneLib }:

craneLib.buildPackage {
  pname = "mold-macho";
  version = "0.1.0-p20260913";

  src = fetchurl {
    url = "https://github.com/rui314/mold-macho/archive/6b259c2bd601cb1e4bb4f46f15e2d3708adc2180.tar.gz";
    sha256 = "1f55355c0deff4382cb262e8683b9ea926e14106308f0bed0f8e00d8c2dfbffe";
  };

  cargoLock = ./Cargo.lock;

  patches = [
    ./tls-dead-strip.patch
  ];

  installPhase = ''
    mkdir -p $out/bin
    if [ -f target/release/mold ]; then
      cp target/release/mold $out/bin/mold
    fi
    ln -sf mold $out/bin/ld64.mold
    ln -sf ld64.mold $out/bin/ld
    ln -sf ld64.mold $out/bin/ld64
    ln -sf ld64.mold $out/bin/arm64-apple-darwin-ld
    ln -sf ld64.mold $out/bin/x86_64-apple-darwin-ld

    cat << 'EOF' > $out/bin/clang-mold
#!/bin/sh
TARGET="$0"
while [ -L "$TARGET" ]; do
  DIR="$(cd "$(dirname "$TARGET")" && pwd)"
  TARGET="$(readlink "$TARGET")"
  case "$TARGET" in
    /*) ;;
    *) TARGET="$DIR/$TARGET" ;;
  esac
done
BINDIR="$(cd "$(dirname "$TARGET")" && pwd)"
exec clang -B"$BINDIR" "$@"
EOF
    chmod 0755 $out/bin/clang-mold
  '';

  meta = {
    description = "High-performance Mach-O linker for macOS (mold for Mach-O / ld64 drop-in)";
    homepage = "https://github.com/rui314/mold-macho";
    license = "MIT";
  };
}
