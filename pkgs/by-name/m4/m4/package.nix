{ stdenv, fetchurl  }:

stdenv.mkDerivation rec {
  pname = "m4";
  version = "1.4.19";

  src = fetchurl {
    url = "https://ftpmirror.gnu.org/m4/m4-${version}.tar.gz";
    sha256 = "3be4a26d825ffdfda52a56fc43246456989a3630093cced3fbddf4771ee58a70";
  };

  configurePhase = ''
    ./configure --prefix=$out
  '';

  buildPhase = ''
    NCPUS=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
    make -j$NCPUS
  '';

  installPhase = ''
    make install
  '';

  meta = {
    description = "GNU M4 macro processor";
    homepage = "https://www.gnu.org/software/m4/";
  };
}
