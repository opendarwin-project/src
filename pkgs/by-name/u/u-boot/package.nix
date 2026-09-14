{ lib, stdenv, fetchurl, lld, gnumake }:

stdenv.mkDerivation rec {
  pname = "u-boot";
  version = "2026.09-main";
  useMold = false;

  src = fetchurl {
    url = "https://github.com/tinted-software/u-boot/archive/45a34be1928e6bd4a802e12e1e9d8d3184128bd7.tar.gz";
    sha256 = "31960abfa4a263d8e4cc1e7c21fe4cac23ac7d2b756d01776022e7301f536dc7";
  };

  nativeBuildInputs = [ lld gnumake ];

  buildCommand = ''
    mkdir -p $out/share/u-boot
    tar -xzf $src --strip-components=1

    make qemu_arm64_defconfig
    if [ -x "scripts/config" ]; then
      scripts/config --enable CMD_BOOTXNU
    fi
    make LLVM=1 -j$NIX_BUILD_CORES

    if [ -f "u-boot.bin" ]; then
      cp u-boot.bin $out/share/u-boot/
    fi
  '';

  meta = {
    description = "tinted-software U-Boot with bootxnu, for qemu virt Darwin bring-up";
    homepage = "https://github.com/tinted-software/u-boot";
    license = "GPL-2.0-only";
  };
}
