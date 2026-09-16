{ lib, stdenv, bootstrap-cmds, iig-tools, xcode-toolchain-wrappers, unifdef, cmake, xcbuild }:
{
  pname,
  version,
  src,
  patches ? [ ],
  darwinKernelVersion ? "27.0.0",
  arch ? (if stdenv.system == "x86_64-darwin" then "X86_64" else "ARM64"),
  kernelConfig ? "RELEASE",
  machineConfig ? (if arch == "X86_64" then "NONE" else "QEMU"),
  extraMakeArgs ? "",
  kernelOutputName ? (if arch == "X86_64" then "xnu.${kernelConfig}_${arch}" else "xnu.${kernelConfig}_${arch}_${machineConfig}"),
  description ? "XNU kernel",
}:
let
  patchList = lib.concatStringsSep " " (builtins.map toString patches);
  targetConfigs = "${kernelConfig} ${arch} ${machineConfig}";
  archString = if arch == "X86_64" then "x86_64" else "arm64";

  availabilityVersionsSrc = fetchurl {
    url = "https://github.com/apple-oss-distributions/AvailabilityVersions/archive/refs/tags/AvailabilityVersions-157.2.tar.gz";
    sha256 = "d92a052edb3c817caa4407868f66f1d93727425a353c2200a41481c27310fdc2";
  };
  libdispatchSrc = fetchurl {
    url = "https://github.com/apple-oss-distributions/libdispatch/archive/refs/tags/libdispatch-1477.100.9.tar.gz";
    sha256 = "97e3cac286e4d521594d4822767cd3b32b18a8ba8841c288451e786f69134c80";
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [ bootstrap-cmds iig-tools xcbuild xcode-toolchain-wrappers unifdef cmake ];

  buildCommand = ''
    mkdir -p $out/lib/opendarwin $out/include
    tar -xzf $src --strip-components=1

    mkdir -p AvailabilityVersions libdispatch
    tar -xzf ${availabilityVersionsSrc} -C AvailabilityVersions --strip-components=1
    tar -xzf ${libdispatchSrc} -C libdispatch --strip-components=1

    for p in ${patchList}; do
      patch -p1 -i "$p"
    done

    # Headers supplied by libdispatch replace the non-public SDK/KDK copies.
    mkdir -p libkern/os iokit/DriverKit/crypto
    cp libdispatch/os/firehose_buffer_private.h libkern/os/
    ln -sf ../IOKit/IOTypes.h iokit/DriverKit/IOTypes.h
    ln -sf ../IOKit/IOReturn.h iokit/DriverKit/IOReturn.h
    ln -sf ../IOKit/IORPC.h iokit/DriverKit/IORPC.h
    ln -sf ../IOKit/IOKitKeys.h iokit/DriverKit/IOKitKeys.h
    ln -sf ../IOKit/IOKernelReportStructs.h iokit/DriverKit/IOKernelReportStructs.h
    ln -sf ../IOKit/IOReportTypes.h iokit/DriverKit/IOReportTypes.h
    ln -sf ../../osfmk/kern/macro_help.h iokit/DriverKit/macro_help.h

    # Hermetic SDK structure; no external KDK required.
    mkdir -p sdk/usr/include sdk/usr/lib sdk/usr/local/libexec sdk/usr/local/lib/kernel sdk/usr/local/include/kernel/os
    if command -v xcrun >/dev/null 2>&1; then
      SYS_SDK="$(xcrun --show-sdk-path 2>/dev/null || true)"
      if [ -n "$SYS_SDK" ] && [ -d "$SYS_SDK/usr/include" ]; then
        ln -sf "$SYS_SDK"/usr/include/* sdk/usr/include/ 2>/dev/null || true
        ln -sf "$SYS_SDK"/usr/lib/* sdk/usr/lib/ 2>/dev/null || true
      fi
    fi
    cp AvailabilityVersions/availability.pl sdk/usr/local/libexec/ 2>/dev/null || true
    cp AvailabilityVersions/availability sdk/usr/local/libexec/ 2>/dev/null || true
    cp AvailabilityVersions/availability.dsl sdk/usr/local/libexec/ 2>/dev/null || true
    cp -R AvailabilityVersions/templates sdk/usr/local/libexec/ 2>/dev/null || true

    make \
      CC="clang" CXX="clang++" HOST_CC="clang" \
      SDKROOT="$(pwd)/sdk" HOST_SDKROOT="/" \
      MIG="${bootstrap-cmds}/bin/mig" MIGCOM="${bootstrap-cmds}/bin/migcom" IIG="${iig-tools}/bin/iig" \
      UNIFDEF="${unifdef}/bin/unifdef" \
      BUILD_WERROR=0 DO_CTFMERGE=0 \
      HOST_CODESIGN=true HOST_CODESIGN_ALLOCATE=true \
      ARCH_CONFIGS="${arch}" \
      KERNEL_CONFIGS="${kernelConfig}" \
      TARGET_CONFIGS="${targetConfigs}" \
      ARCH_STRING_FOR_CURRENT_MACHINE_CONFIG="${archString}" \
      RC_DARWIN_KERNEL_VERSION="${darwinKernelVersion}" \
      KERNEL_BUILDS_IN_PARALLEL=1 \
      OBJROOT="$(pwd)/BUILD/obj" SYMROOT="$(pwd)/BUILD/sym" DSTROOT="$(pwd)/BUILD/dst" \
      ${extraMakeArgs}

    find BUILD/sym -name 'kernel*' -type f -exec cp {} $out/lib/opendarwin/${kernelOutputName} \; -quit
  '';

  meta = {
    inherit description;
    homepage = "https://github.com/apple-oss-distributions/xnu";
    license = [ "APSL-2.0" "Apache-2.0" ];
  };
}
