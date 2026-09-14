{ lib, stdenv, fetchurl, cmake, ninja  }:

stdenv.mkDerivation rec {
  pname = "iig-tools";
  version = "0.1.0-p20260913";

  src = fetchurl {
    url = "https://github.com/opendarwin-project/iig-tools/archive/96c1ece6be1ceb6ee2fec6c434d080edc10da2b1.tar.gz";
    sha256 = "af82826fc33fca00dfa6d0496340993e58906695245923570f50e4c316e0a54e";
  };

  nativeBuildInputs = [ cmake ninja ];

  cmakeFlags = "-G Ninja";

  meta = {
    description = "I/O Kit Interface Generator (iig) implementation";
    homepage = "https://github.com/opendarwin-project/iig-tools";
    license = "BSD-3-Clause";
  };
}
