{ lib, stdenv, fetchurl, m4 }:

stdenv.mkDerivation rec {
  pname = "bison";
  version = "3.8.2";

  src = fetchurl {
    url = "https://ftp.gnu.org/gnu/bison/bison-${version}.tar.xz";
    sha256 = "9bba0214ccf7f1079c5d59210045227bcf619519840ebfa80cd3849cff5a5bf2";
  };

  nativeBuildInputs = [ m4 ];

  buildCommand = ''
    tar -xf $src --strip-components=1
    ./configure --prefix=$out --disable-nls
    make -j$NIX_BUILD_CORES
    make install
  '';

  meta = {
    description = "GNU parser generator (a yacc replacement)";
    homepage = "https://www.gnu.org/software/bison/";
    license = "GPL-3.0-or-later";
  };
}
