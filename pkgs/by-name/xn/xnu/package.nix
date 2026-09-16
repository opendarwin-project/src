{ lib, stdenv, fetchurl, bootstrap-cmds, iig-tools, xcode-toolchain-wrappers, unifdef, cmake, xcbuild }:

(import ./common.nix {
  inherit lib stdenv bootstrap-cmds iig-tools xcode-toolchain-wrappers unifdef cmake xcbuild;
}) rec {
  pname = "xnu";
  version = "12377.121.6";

  src = fetchurl {
    url = "https://github.com/apple-oss-distributions/xnu/archive/refs/tags/xnu-${version}.tar.gz";
    sha256 = "3898466e5f4ba16c6e2ea291987e097792349a0b34dda89191c4b5e8da29118c";
  };

  patches = [
    ./patches/tahoe/0001-external-headers.patch
    ./patches/tahoe/0002-arm64-board-support.patch
    ./patches/tahoe/0003-oss-build-config.patch
    ./patches/tahoe/0004-oss-kernel-fixes.patch
    ./patches/tahoe/0005-iorpc-message-from-mach.patch
    ./patches/tahoe/0006-guard-sptm-user-pointer-ops-with-pac.patch
    ./patches/tahoe/0007-simplify-san-lipo.patch
    ./patches/tahoe/0008-dsymutil-no-process-substitution.patch
    ./patches/tahoe/0009-add-firehose-buffer.patch
    ./patches/tahoe/0010-use-thin-lto.patch
    ./patches/tahoe/0011-fix-duplicate-symbols.patch
  ];

  # Default to QEMU on ARM64, or NONE on x86_64
  arch = if stdenv.system == "x86_64-darwin" then "X86_64" else "ARM64";
  machineConfig = if arch == "X86_64" then "NONE" else "QEMU";
  kernelConfig = "RELEASE";
  darwinKernelVersion = "27.0.0";
  extraMakeArgs = "MEMORY_SIZE=17179869184";
  description = "OpenDarwin XNU kernel for macOS 16 Tahoe (ARM64 QEMU/VMAPPLE or X86_64)";
}
