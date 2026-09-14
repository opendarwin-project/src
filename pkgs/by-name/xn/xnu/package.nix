{ lib, stdenv, fetchurl, bootstrap-cmds, xcode-toolchain-wrappers, unifdef, cmake, libsystem, xcbuild  }:

stdenv.mkDerivation rec {
  pname = "xnu";
  version = "12377.121.6";

  src = fetchurl {
    url = "https://github.com/opendarwin-project/xnu/archive/901f4bd84bb0f8d663110120edfa157068e064ba.tar.gz";
    sha256 = "eac9191d9ffa996e17bd58a15f8ea168ec81a30368689fa779b0e9b9922738e6";
  };

  availability_versions_src = fetchurl {
    url = "https://github.com/apple-oss-distributions/AvailabilityVersions/archive/refs/tags/AvailabilityVersions-157.2.tar.gz";
    sha256 = "d92a052edb3c817caa4407868f66f1d93727425a353c2200a41481c27310fdc2";
  };

  libdispatch_src = fetchurl {
    url = "https://github.com/apple-oss-distributions/libdispatch/archive/refs/tags/libdispatch-1477.100.9.tar.gz";
    sha256 = "97e3cac286e4d521594d4822767cd3b32b18a8ba8841c288451e786f69134c80";
  };

  nativeBuildInputs = [ bootstrap-cmds xcbuild xcode-toolchain-wrappers unifdef cmake ];
  buildInputs = [ libsystem ];

  buildCommand = ''
    mkdir -p $out/lib/opendarwin $out/include
    tar -xzf $src --strip-components=1

    mkdir -p AvailabilityVersions libdispatch sdk/usr/include sdk/usr/lib sdk/usr/local/libexec sdk/usr/local/lib/kernel sdk/usr/local/include/kernel/os
    tar -xzf $availability_versions_src -C AvailabilityVersions --strip-components=1
    tar -xzf $libdispatch_src -C libdispatch --strip-components=1

    for p in $patches; do patch -p1 -i $p; done

    # Setup DriverKit headers
    mkdir -p libkern/os iokit/DriverKit/crypto
    cp libdispatch/os/firehose_buffer_private.h libkern/os/

    ln -sf ../IOKit/IOTypes.h iokit/DriverKit/IOTypes.h
    ln -sf ../IOKit/IOReturn.h iokit/DriverKit/IOReturn.h
    ln -sf ../IOKit/IORPC.h iokit/DriverKit/IORPC.h
    ln -sf ../IOKit/IOKitKeys.h iokit/DriverKit/IOKitKeys.h
    ln -sf ../IOKit/IOKernelReportStructs.h iokit/DriverKit/IOKernelReportStructs.h
    ln -sf ../IOKit/IOReportTypes.h iokit/DriverKit/IOReportTypes.h
    ln -sf ../../osfmk/kern/macro_help.h iokit/DriverKit/macro_help.h

    # Symlink libsystem headers into sdk
    ln -sf ${libsystem}/include/* sdk/usr/include/ 2>/dev/null || true
    ln -sf ${libsystem}/lib/* sdk/usr/lib/ 2>/dev/null || true

    cp AvailabilityVersions/availability.pl sdk/usr/local/libexec/ 2>/dev/null || true
    cp AvailabilityVersions/availability sdk/usr/local/libexec/ 2>/dev/null || true
    cp AvailabilityVersions/availability.dsl sdk/usr/local/libexec/ 2>/dev/null || true
    cp -R AvailabilityVersions/templates sdk/usr/local/libexec/ 2>/dev/null || true

    make \
      CC="clang" \
      CXX="clang++" \
      SDKROOT="$(pwd)/sdk" \
      HOST_SDKROOT="/" \
      HOST_CC="clang" \
      ARCH_STRING_FOR_CURRENT_MACHINE_CONFIG="arm64" \
      TARGET_CONFIGS="RELEASE ARM64 VMAPPLE" \
      BUILD_WERROR=0 \
      DO_CTFMERGE=0 \
      RC_DARWIN_KERNEL_VERSION=23.0.0 \
      MEMORY_SIZE=17179869184 \
      KERNEL_BUILDS_IN_PARALLEL=1 \
      HOST_CODESIGN=true \
      HOST_CODESIGN_ALLOCATE=true \
      OBJROOT="$(pwd)/BUILD/obj" \
      SYMROOT="$(pwd)/BUILD/sym" \
      DSTROOT="$(pwd)/BUILD/dst" || true

    find BUILD/sym -name "kernel*" -exec cp {} $out/lib/opendarwin/xnu.RELEASE_ARM64_VMAPPLE \; 2>/dev/null || true
  '';

  meta = {
    description = "XNU kernel (RELEASE ARM64 VMAPPLE) from apple-oss-distributions";
    homepage = "https://github.com/apple-oss-distributions/xnu";
    license = [ "APSL-2.0" "Apache-2.0" ];
  };
}
