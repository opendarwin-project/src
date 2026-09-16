{ lib, stdenv, fetchurl, bootstrap-cmds, iig-tools, xcode-toolchain-wrappers, unifdef, cmake, xcbuild }:

(import ../xnu/common.nix {
  inherit lib stdenv bootstrap-cmds iig-tools xcode-toolchain-wrappers unifdef cmake xcbuild;
}) {
  pname = "xnu-macos15";
  version = "11417.140.69";

  src = fetchurl {
    url = "https://github.com/apple-oss-distributions/xnu/archive/refs/tags/xnu-11417.140.69.tar.gz";
    sha256 = "6ec42735d647976a429331cdc73a35e8f3889b56c251397c05989a59063dc251";
  };
  availabilityVersionsSrc = fetchurl {
    url = "https://github.com/apple-oss-distributions/AvailabilityVersions/archive/refs/tags/AvailabilityVersions-157.2.tar.gz";
    sha256 = "d92a052edb3c817caa4407868f66f1d93727425a353c2200a41481c27310fdc2";
  };
  libdispatchSrc = fetchurl {
    url = "https://github.com/apple-oss-distributions/libdispatch/archive/refs/tags/libdispatch-1477.100.9.tar.gz";
    sha256 = "97e3cac286e4d521594d4822767cd3b32b18a8ba8841c288451e786f69134c80";
  };

  patches = [
    ./patches/macos15-no-kdk/0001-firehose-no-kdk-x86_64.patch
    ./patches/macos15-no-kdk/0002-simplify-san-lipo.patch
    ./patches/macos15-no-kdk/0003-dsymutil-no-process-substitution.patch
    ./patches/macos15-no-kdk/0004-thinlto.patch
  ];

  arch = "X86_64";
  machineConfig = "NONE";
  kernelConfig = "RELEASE";
  darwinKernelVersion = "24.6.0";
  extraMakeArgs = "MEMORY_SIZE=12884901888";
  description = "macOS 15.8-compatible XNU RELEASE kernel (x86_64) without a KDK";
}
