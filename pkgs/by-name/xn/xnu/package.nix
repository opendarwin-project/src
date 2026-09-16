{ lib, stdenv, fetchurl, bootstrap-cmds, iig-tools, xcode-toolchain-wrappers, unifdef, cmake, xcbuild }:

(import ./common.nix {
  inherit lib stdenv bootstrap-cmds iig-tools xcode-toolchain-wrappers unifdef cmake xcbuild;
}) rec {
  pname = "xnu";
  version = "12377.121.6";
  
  src = fetchurl {
    url = "https://github.com/apple-oss-distributions/xnu/archive/xnu-${version}.tar.gz";
    sha256 = "3898466e5f4ba16c6e2ea291987e097792349a0b34dda89191c4b5e8da29118c";
  };

  patches = [
    ./patches/0000-external-headers.patch
    ./patches/0001-firehose-no-kdk-tahoe-x86_64.patch
    ./patches/0002-simplify-san-lipo.patch
    ./patches/0003-dsymutil-no-process-substitution.patch
    ./patches/0004-thinlto.patch
    ./patches/0005-iorpc-message-from-mach.patch
  ];

  arch = "ARM64";
  machineConfig = "QEMU";
  kernelConfig = "RELEASE";
  darwinKernelVersion = "23.0.0";
  extraMakeArgs = "MEMORY_SIZE=17179869184";
  description = "XNU kernel (RELEASE ARM64 QEMU) from apple-oss-distributions";
}
