{ stdenv, fetchurl  }:

stdenv.mkDerivation rec {
  pname = "gnumake";
  version = "4.4.1";

  src = fetchurl {
    url = "https://ftpmirror.gnu.org/make/make-${version}.tar.gz";
    sha256 = "dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3";
  };

  configurePhase = ''
    ./configure --prefix=$out --without-guile
  '';

  buildPhase = ''
    NCPUS=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
    make -j$NCPUS
  '';

  installPhase = ''
    make install
    ln -sf make $out/bin/gmake
  '';

  meta = {
    description = "GNU Make build automation tool";
    homepage = "https://www.gnu.org/software/make/";
  };
}
