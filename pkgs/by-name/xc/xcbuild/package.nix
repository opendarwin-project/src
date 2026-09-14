{ lib, stdenv, fetchurl, cmake, ninja  }:

stdenv.mkDerivation rec {
  pname = "xcbuild";
  version = "0.1.0-p20260913";

  src = fetchurl {
    url = "https://github.com/opendarwin-project/xcbuild/archive/9fd95496a67731266e7f43fec36a4249ec6f1dec.tar.gz";
    sha256 = "08c7a154ba3602d5220930875d4c5a88cd0f4678fe03d752a88f9ad206aa53a2";
  };

  linenoise_src = fetchurl {
    url = "https://github.com/antirez/linenoise/archive/master.tar.gz";
    sha256 = "f822dd5c4d7e43b18e9a06f0c1d6f39b89b3c9a3806b54e68ba578a364b2eeae";
  };

  googletest_src = fetchurl {
    url = "https://github.com/google/googletest/archive/refs/tags/v1.14.0.tar.gz";
    sha256 = "8ad598c73ad796e0d8280b082cebd82a630d73e73cd3c70057938a6501bba5d7";
  };

  nativeBuildInputs = [ cmake ninja ];

  unpackPhase = ''
    mkdir -p ThirdParty/linenoise ThirdParty/googletest
    tar -xzf $linenoise_src -C ThirdParty/linenoise --strip-components=1
    tar -xzf $googletest_src -C ThirdParty/googletest --strip-components=1
  '';

  cmakeFlags = "-G Ninja";

  meta = {
    description = "Reimplementation of Apple's Xcode build tools (xcodebuild) for OpenDarwin/Linux";
    homepage = "https://github.com/opendarwin-project/xcbuild";
    license = "BSD-3-Clause";
  };
}
