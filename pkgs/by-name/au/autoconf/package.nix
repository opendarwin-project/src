{ stdenv, fetchurl, m4  }:

stdenv.mkDerivation rec {
  pname = "autoconf";
  version = "2.72";

  src = fetchurl {
    url = "https://ftp.gnu.org/gnu/autoconf/autoconf-${version}.tar.gz";
    sha256 = "afb181a76e1ee72832f6581c0eddf8df032b83e2e0239ef79ebedc4467d92d6e";
  };

  buildInputs = [ m4 ];

  configurePhase = ''
    M4=${m4}/bin/m4 ./configure --prefix=$out
  '';

  buildPhase = ''
    NCPUS=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
    make -j$NCPUS
  '';

  installPhase = ''
    make install
  '';

  meta = {
    description = "Extensible package of M4 macros to produce shell scripts for configuring software";
    homepage = "https://www.gnu.org/software/autoconf/";
  };
}
