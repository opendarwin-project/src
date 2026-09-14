{ lib, stdenv, fetchurl  }:

stdenv.mkDerivation rec {
  pname = "xcode-toolchain-wrappers";
  version = "1.0.0";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/opendarwin-project/src/main/overlay/sys-devel/xcode-toolchain-wrappers/xcode-toolchain-wrappers-1.ebuild";
    sha256 = "89a87658128fc2aaace93f0172f1d6c0111c20b77a4d5d1d2a44f5a0627534e4";
  };

  sw_vers_src = fetchurl {
    url = "https://raw.githubusercontent.com/opendarwin-project/src/main/overlay/sys-devel/xcode-toolchain-wrappers/files/sw_vers";
    sha256 = "6a7a2c0b7cf62d118b45e14d2687d757235eb440225b1c5c0efed7ab1b84755c";
  };

  codesign_src = fetchurl {
    url = "https://raw.githubusercontent.com/opendarwin-project/src/main/overlay/sys-devel/xcode-toolchain-wrappers/files/codesign";
    sha256 = "ac3547094ececc836877699de8bd8d417d97e6b0bc2c2162b3622a10b0743a27";
  };

  sysctl_src = fetchurl {
    url = "https://raw.githubusercontent.com/opendarwin-project/src/main/overlay/sys-devel/xcode-toolchain-wrappers/files/sysctl";
    sha256 = "8879bc11f707f32d397981fd9dea17836c1cae85e2b29480a067498542b1dc6f";
  };

  buildCommand = ''
    mkdir -p $out/bin $out/libexec/darwin
    cp $sw_vers_src $out/bin/sw_vers
    cp $codesign_src $out/bin/codesign
    cp $sysctl_src $out/libexec/darwin/sysctl
    chmod +x $out/bin/* $out/libexec/darwin/*

    ln -sf codesign $out/bin/codesign_allocate
  '';

  meta = {
    description = "Xcode toolchain compatibility wrappers (xcrun, sw_vers, codesign) for LLVM";
    homepage = "https://github.com/opendarwin-project";
    license = "MIT";
  };
}
