{ lib, stdenv, fetchurl, bootstrap-cmds, iig-tools, xcode-toolchain-wrappers, unifdef, cmake, xcbuild }:

(import ./common.nix {
  inherit fetchurl lib stdenv bootstrap-cmds iig-tools xcode-toolchain-wrappers unifdef cmake xcbuild;
}) rec {
  pname = "xnu";
  version = "12377.121.6";

  src = fetchurl {
    url = "https://github.com/opendarwin-project/xnu/archive/09c2eb8ecf6c8a07d4ac1b482f8860578a048850.tar.gz";
    sha256 = "04f4375f0ed085a248f0b1bcdb8ad19f7226f663d16392f16d9206962eaa16bd";
  };

  patches = [
    ./patches/0001-external-headers.patch
    ./patches/0002-arm64-board-support.patch
    ./patches/0003-oss-build-config.patch
    ./patches/0004-oss-kernel-fixes.patch
    ./patches/0005-iorpc-message-from-mach.patch
    ./patches/0006-guard-sptm-user-pointer-ops-with-pac.patch
    ./patches/0007-simplify-san-lipo.patch
    ./patches/0008-dsymutil-no-process-substitution.patch
    ./patches/0009-add-firehose-buffer.patch
    ./patches/0010-use-thin-lto.patch
    ./patches/0011-fix-duplicate-symbols.patch
  ];

  # Default to QEMU on ARM64, or NONE on x86_64
  arch = if stdenv.system == "x86_64-darwin" then "X86_64" else "ARM64";
  machineConfig = if arch == "X86_64" then "NONE" else "QEMU";
  kernelConfig = "RELEASE";
  darwinKernelVersion = "27.0.0";
  enableLto = true;
  extraMakeArgs = "MEMORY_SIZE=17179869184";
  description = "OpenDarwin XNU kernel for macOS 16 Tahoe (ARM64 QEMU/VMAPPLE or X86_64)";
}
