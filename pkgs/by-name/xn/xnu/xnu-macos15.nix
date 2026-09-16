{ lib, stdenv, fetchurl, bootstrap-cmds, iig-tools, xcode-toolchain-wrappers, unifdef, cmake, xcbuild }:

(import ./common.nix {
  inherit lib stdenv bootstrap-cmds iig-tools xcode-toolchain-wrappers unifdef cmake xcbuild;
}) rec {
  pname = "xnu-macos15";
  version = "11417.140.69";

  src = fetchurl {
    url = "https://github.com/apple-oss-distributions/xnu/archive/refs/tags/xnu-${version}.tar.gz";
    sha256 = "6ec42735d647976a429331cdc73a35e8f3889b56c251397c05989a59063dc251";
  };

  patches = [
    ./patches/0000-external-headers-macos15.patch
    ./patches/0001-firehose-no-kdk-macos15-x86_64.patch
    ./patches/0002-simplify-san-lipo.patch
    ./patches/0003-dsymutil-no-process-substitution.patch
    ./patches/0004-thinlto.patch
    ./patches/0005-iorpc-message-from-mach.patch
  ];

  arch = "X86_64";
  machineConfig = "NONE";
  kernelConfig = "RELEASE";
  darwinKernelVersion = "24.6.0";
  extraMakeArgs = "MEMORY_SIZE=12884901888";
  description = "macOS 15.8-compatible XNU RELEASE kernel (x86_64) without a KDK";
}
