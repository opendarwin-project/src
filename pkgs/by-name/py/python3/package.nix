{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "python3";
  version = "3.15.0rc2";

  src = fetchurl {
    url = "https://www.python.org/ftp/python/3.15.0/Python-3.15.0rc2.tar.xz";
    sha256 = "8d93af5eaaaea5adfd41bd786a7ba3f03f2ad1ab57c6a65e0b963deab91d5ad7";
  };

  configurePhase = ''
    ./configure --prefix=$out --enable-optimizations --with-ensurepip=no --enable-shared=no
  '';

  buildPhase = ''
    make -j$(sysctl -n hw.ncpu 2>/dev/null || echo 2)
  '';

  installPhase = ''
    make install
  '';

  meta = {
    description = "Python 3.15 interpreter";
    homepage = "https://www.python.org/";
  };
}
