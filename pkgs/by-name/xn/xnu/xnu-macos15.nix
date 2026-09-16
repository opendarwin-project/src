{ lib, stdenv, fetchurl, bootstrap-cmds, iig-tools, xcode-toolchain-wrappers, unifdef, cmake, xcbuild }:

(import ../xnu/common.nix {
  inherit lib stdenv bootstrap-cmds iig-tools xcode-toolchain-wrappers unifdef cmake xcbuild;
}) rec {
  pname = "xnu-macos15";
  version = "11417.140.69";
  
  src = fetchurl {
    url = "https://github.com/apple-oss-distributions/xnu/archive/xnu-${version}.tar.gz";
    sha256 = "3898466e5f4ba16c6e2ea291987e097792349a0b34dda89191c4b5e8da29118c";
  };

  patches = [
    ./patches/0001-firehose-no-kdk-x86_64.patch
    ./patches/0002-simplify-san-lipo.patch
    ./patches/0003-dsymutil-no-process-substitution.patch
    ./patches/0004-thinlto.patch
  ];

  arch = "X86_64";
  machineConfig = "NONE";
  kernelConfig = "RELEASE";
  darwinKernelVersion = "24.6.0";
  extraMakeArgs = "MEMORY_SIZE=12884901888";
  description = "macOS 15.8-compatible XNU RELEASE kernel (x86_64) without a KDK";
}
