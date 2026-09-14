{ stdenv, fetchurl, autoconf  }:

stdenv.mkDerivation rec {
  pname = "automake";
  version = "1.17";

  src = fetchurl {
    url = "https://ftpmirror.gnu.org/automake/automake-${version}.tar.gz";
    sha256 = "397767d4db3018dd4440825b60c64258b636eaf6bf99ac8b0897f06c89310acd";
  };

  buildInputs = [ autoconf ];

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
    description = "Tool for automatically generating `Makefile.in` files complying with the GNU standards";
    homepage = "https://www.gnu.org/software/automake/";
  };
}
