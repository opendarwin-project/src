{ lib, stdenv, fetchurl, bootstrap-cmds, iig-tools, xcode-toolchain-wrappers, unifdef, cmake, ninja, xcbuild }:

# Header-only companion to `xnu`.
#
# Runs the kernel's `make installhdrs` target and installs the resulting SDK
# tree.  This produces the internal-SDK layout that user-space projects such as
# dyld expect:
#
#   System.framework/Versions/B/PrivateHeaders/<sys,machine,mach,os,...>
#   usr/include/<sys,mach,...>
#   usr/local/include/<machine,os,...>
#
# Crucially this avoids building the kernel itself, so libsystem (which needs
# these headers) does not have to wait on a full XNU build.
stdenv.mkDerivation rec {
  pname = "xnu-headers";
  version = "12377.121.6";

  src = fetchurl {
    url = "https://github.com/apple-oss-distributions/xnu/archive/refs/tags/xnu-${version}.tar.gz";
    sha256 = "3898466e5f4ba16c6e2ea291987e097792349a0b34dda89191c4b5e8da29118c";
  };

  patches = [
    ../xnu/patches/tahoe/0001-external-headers.patch
    ../xnu/patches/tahoe/0002-arm64-board-support.patch
    ../xnu/patches/tahoe/0003-oss-build-config.patch
    ../xnu/patches/tahoe/0004-oss-kernel-fixes.patch
    ../xnu/patches/tahoe/0005-iorpc-message-from-mach.patch
    ../xnu/patches/tahoe/0006-guard-sptm-user-pointer-ops-with-pac.patch
    ../xnu/patches/tahoe/0007-simplify-san-lipo.patch
    ../xnu/patches/tahoe/0008-dsymutil-no-process-substitution.patch
    ../xnu/patches/tahoe/0009-add-firehose-buffer.patch
    ../xnu/patches/tahoe/0010-use-thin-lto.patch
    ../xnu/patches/tahoe/0011-fix-duplicate-symbols.patch
  ];

  availabilityVersionsSrc = fetchurl {
    url = "https://github.com/apple-oss-distributions/AvailabilityVersions/archive/refs/tags/AvailabilityVersions-157.2.tar.gz";
    sha256 = "d92a052edb3c817caa4407868f66f1d93727425a353c2200a41481c27310fdc2";
  };

  nativeBuildInputs = [ bootstrap-cmds iig-tools xcbuild xcode-toolchain-wrappers unifdef cmake ninja ];

  buildCommand = ''
    tar -xzf $src --strip-components=1
    for p in $patches; do
      patch -p1 -i "$p"
    done

    # Hermetic SDK: public headers from the host SDK, plus the local
    # AvailabilityVersions tooling that the unifdef header pass expects.
    mkdir -p sdk/usr/include sdk/usr/lib sdk/usr/local/libexec sdk/usr/local/lib/kernel sdk/usr/local/include/kernel/os
    if command -v xcrun >/dev/null 2>&1; then
      SYS_SDK="$(xcrun --show-sdk-path 2>/dev/null || true)"
      if [ -n "$SYS_SDK" ] && [ -d "$SYS_SDK/usr/include" ]; then
        ln -sf "$SYS_SDK"/usr/include/* sdk/usr/include/ 2>/dev/null || true
        ln -sf "$SYS_SDK"/usr/lib/* sdk/usr/lib/ 2>/dev/null || true
      fi
    fi
    mkdir -p AvailabilityVersions
    tar -xzf $availabilityVersionsSrc -C AvailabilityVersions --strip-components=1
    cp AvailabilityVersions/availability.pl sdk/usr/local/libexec/ 2>/dev/null || true
    cp AvailabilityVersions/availability sdk/usr/local/libexec/ 2>/dev/null || true
    cp AvailabilityVersions/availability.dsl sdk/usr/local/libexec/ 2>/dev/null || true
    cp -R AvailabilityVersions/templates sdk/usr/local/libexec/ 2>/dev/null || true

    make installhdrs \
      CC="clang" CXX="clang++" HOST_CC="clang" \
      SDKROOT="$(pwd)/sdk" HOST_SDKROOT="/" \
      MIG="${bootstrap-cmds}/bin/mig" MIGCOM="${bootstrap-cmds}/bin/migcom" IIG="${iig-tools}/bin/iig" \
      UNIFDEF="${unifdef}/bin/unifdef" \
      BUILD_WERROR=0 DO_CTFMERGE=0 \
      HOST_CODESIGN=true HOST_CODESIGN_ALLOCATE=true \
      SDKVERSION="27.0" \
      ARCH_CONFIGS="ARM64" KERNEL_CONFIGS="RELEASE" \
      TARGET_CONFIGS="RELEASE ARM64 QEMU" \
      ARCH_STRING_FOR_CURRENT_MACHINE_CONFIG="arm64" \
      RC_DARWIN_KERNEL_VERSION="27.0.0" \
      KERNEL_BUILDS_IN_PARALLEL=1 \
      OBJROOT="$(pwd)/BUILD/obj" SYMROOT="$(pwd)/BUILD/sym" DSTROOT="$(pwd)/BUILD/dst"

    # Generate the availability/versioning macro headers from AvailabilityVersions.
    # These are the "internal" <Availability.h> family (they understand every
    # Apple platform, e.g. bridgeos), which the private xnu headers require.
    make -C AvailabilityVersions install \
      CMAKE="${cmake}/bin/cmake" NINJA="${ninja}/bin/ninja" \
      SRCROOT="$(pwd)/AvailabilityVersions" \
      OBJROOT="$(pwd)/av-obj" SYMROOT="$(pwd)/av-sym" DSTROOT="$(pwd)/av-dst" \
      RC_ProjectNameAndBuildVersion="27.0.0"

    mkdir -p $out
    cp -R BUILD/dst/. $out/
    cp -R av-dst/. $out/
  '';

  meta = {
    description = "XNU userspace/kernel header tree (internal SDK layout)";
    homepage = "https://github.com/apple-oss-distributions/xnu";
    license = [ "APSL-2.0" "Apache-2.0" ];
  };
}
