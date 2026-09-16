{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "unifdef";
  version = "2.12";

  src = fetchurl {
    url = "https://dotat.at/prog/unifdef/unifdef-${version}.tar.gz";
    sha256 = "fba564a24db7b97ebe9329713ac970627b902e5e9e8b14e19e024eb6e278d10b";
  };

  buildCommand = ''
    tar -xzf $src --strip-components=1
    make CC=clang CFLAGS="-O2"
    make install prefix=$out
  '';

  meta = {
    description = "Selectively remove #ifdef lines from source files";
    homepage = "https://dotat.at/prog/unifdef/";
    license = "BSD-2-Clause";
  };
}
