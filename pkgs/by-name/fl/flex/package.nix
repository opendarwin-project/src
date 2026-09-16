{ lib, stdenv, fetchurl, m4, bison }:

stdenv.mkDerivation rec {
  pname = "flex";
  version = "2.6.4";

  src = fetchurl {
    url = "https://github.com/westes/flex/releases/download/v${version}/flex-${version}.tar.gz";
    sha256 = "e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995";
  };

  nativeBuildInputs = [ m4 bison ];

  buildCommand = ''
    tar -xzf $src --strip-components=1
    ./configure --prefix=$out --disable-shared --disable-nls
    make -j$NIX_BUILD_CORES MAKEINFO=true
    make install MAKEINFO=true
  '';

  meta = {
    description = "Fast lexical analyzer generator";
    homepage = "https://github.com/westes/flex";
    license = "BSD-2-Clause";
  };
}
