{ lib, stdenv, fetchurl, xcbuild, xcode-toolchain-wrappers, libsystem  }:

stdenv.mkDerivation rec {
  pname = "dyld";
  version = "1165.3";

  src = fetchurl {
    url = "https://github.com/apple-oss-distributions/dyld/archive/refs/tags/dyld-1165.3.tar.gz";
    sha256 = "f2cd78cdcf9d63011d0cee0047033b0815355a9f5d25df2a0690b47a05602e5f";
  };

  patches = [
    ./linux-compat.patch
  ];

  nativeBuildInputs = [ xcbuild xcode-toolchain-wrappers ];
  buildInputs = [ libsystem ];

  buildCommand = ''
    mkdir -p $out/bin $out/lib/system $out/include
    tar -xzf $src --strip-components=1
    for p in $patches; do patch -p1 -i $p; done

    symroot="$(pwd)/sym"
    objroot="$(pwd)/obj"

    xcodebuild \
      -project dyld.xcodeproj \
      -target dyld \
      -target libdyld.dylib \
      -configuration Release \
      ARCHS="${if stdenv.system == "x86_64-darwin" then "x86_64" else "arm64"}" \
      SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" \
      OTHER_LDFLAGS="-Wl,-undefined,dynamic_lookup" \
      OTHER_CFLAGS="-DBUILDING_DYLD=1 -DBUILDING_LIBDYLD=1 -DDYLD_VERSION=${version}" \
      USER_HEADER_SEARCH_PATHS="./dyld ./common ./mach_o" \
      CLANG_CXX_LANGUAGE_STANDARD=c++20 \
      GCC_C_LANGUAGE_STANDARD=c2x \
      SYMROOT="$symroot" \
      OBJROOT="$objroot" \
      build

    build_dir="$symroot/Release"
    if [ -f "$build_dir/dyld" ]; then
      cp "$build_dir/dyld" $out/lib/
    fi
    if [ -f "$build_dir/libdyld.dylib" ]; then
      cp "$build_dir/libdyld.dylib" $out/lib/system/
      ln -sf system/libdyld.dylib $out/lib/libdyld.dylib
    fi

    if [ -d "include" ]; then
      cp -R include/* $out/include/
    fi
  '';

  meta = {
    description = "Apple's dynamic linker (dyld) and libdyld runtime";
    homepage = "https://github.com/apple-oss-distributions/dyld";
    license = "APSL-2.0";
  };
}
